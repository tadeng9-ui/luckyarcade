-- Run this whole file in Supabase SQL Editor. All balances are virtual game coins.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 username text unique not null check (char_length(username) between 3 and 20),
 coins bigint not null default 10000 check (coins >= 0),
 loan bigint not null default 0 check (loan >= 0 and loan <= 100000),
 total_won bigint not null default 0,
 total_lost bigint not null default 0,
 last_allowance_at timestamptz not null default now(),
 created_at timestamptz not null default now()
);
create table if not exists public.friend_requests (
 id uuid primary key default gen_random_uuid(),
 sender uuid not null references public.profiles(id) on delete cascade,
 receiver uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','accepted','rejected')),
 created_at timestamptz not null default now(),
 unique(sender,receiver), check(sender <> receiver)
);
create table if not exists public.friendships (
 user_a uuid not null references public.profiles(id) on delete cascade,
 user_b uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_a,user_b), check(user_a < user_b)
);
create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references public.profiles(id) on delete cascade,
 room text not null check(room in ('lobby','dm')),
 participants uuid[] not null default '{}',
 body text not null check(char_length(body) between 1 and 500),
 created_at timestamptz not null default now()
);
create index if not exists messages_created_idx on public.messages(created_at desc);
create table if not exists public.game_history (
 id bigint generated always as identity primary key,
 user_id uuid not null references public.profiles(id) on delete cascade,
 game text not null,
 bet bigint not null,
 delta bigint not null,
 detail text not null,
 created_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare uname text;
begin
 uname := coalesce(nullif(trim(new.raw_user_meta_data->>'username'),''), 'player_'||substr(new.id::text,1,8));
 insert into public.profiles(id,username) values(new.id, left(uname,20));
 return new;
exception when unique_violation then
 insert into public.profiles(id,username) values(new.id, left(uname,14)||'_'||substr(new.id::text,1,5));
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace view public.leaderboard with (security_invoker = true) as
 select id, username, coins, total_won, total_lost from public.profiles order by coins desc;

create or replace view public.friend_view with (security_invoker = true) as
 select f.user_a as owner_id, p.id, p.username from public.friendships f join public.profiles p on p.id=f.user_b
 union all
 select f.user_b as owner_id, p.id, p.username from public.friendships f join public.profiles p on p.id=f.user_a;

create or replace view public.friend_requests_inbox with (security_invoker = true) as
 select r.id, r.receiver as owner_id, r.sender, p.username, r.created_at from public.friend_requests r join public.profiles p on p.id=r.sender where r.status='pending';

alter table public.profiles enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.messages enable row level security;
alter table public.game_history enable row level security;

create policy "profiles readable for community" on public.profiles for select to authenticated using (true);
-- No direct UPDATE policy on profiles: balances are changed only by server-side RPCs.
create policy "requests visible to participants" on public.friend_requests for select to authenticated using(auth.uid()=sender or auth.uid()=receiver);
create policy "friendships visible to members" on public.friendships for select to authenticated using(auth.uid()=user_a or auth.uid()=user_b);
create policy "messages readable if allowed" on public.messages for select to authenticated using(
 (room='lobby') or (room='dm' and auth.uid()=any(participants))
);
create policy "history own only" on public.game_history for select to authenticated using(auth.uid()=user_id);

-- Claim allowance: once per elapsed minute, with a cap of 24 hours of offline rewards.
create or replace function public.claim_allowance() returns jsonb language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid(); p public.profiles%rowtype; mins integer; amount bigint;
begin
 if uid is null then raise exception '请先登录'; end if;
 select * into p from public.profiles where id=uid for update;
 mins := least(1440, greatest(0, floor(extract(epoch from (now()-p.last_allowance_at))/60)::integer));
 amount := mins::bigint*50000;
 if mins>0 then
  update public.profiles set coins=coins+amount,last_allowance_at=last_allowance_at+make_interval(mins=>mins) where id=uid;
  insert into public.game_history(user_id,game,bet,delta,detail) values(uid,'allowance',0,amount,mins||' 分钟奖励');
 end if;
 return jsonb_build_object('granted',amount,'minutes',mins);
end; $$;

create or replace function public.take_loan() returns jsonb language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid(); p public.profiles%rowtype;
begin
 if uid is null then raise exception '请先登录'; end if;
 select * into p from public.profiles where id=uid for update;
 if p.loan>=100000 then raise exception '已达到借款上限'; end if;
 update public.profiles set coins=coins+10000,loan=loan+10000 where id=uid;
 insert into public.game_history(user_id,game,bet,delta,detail) values(uid,'loan',0,10000,'借入虚拟游戏币');
 return jsonb_build_object('coins_added',10000);
end; $$;

create or replace function public.send_friend_request(p_username text) returns jsonb language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid(); target uuid;
begin
 if uid is null then raise exception '请先登录'; end if;
 select id into target from public.profiles where lower(username)=lower(trim(p_username));
 if target is null then raise exception '找不到这个玩家'; end if;
 if target=uid then raise exception '不能添加自己'; end if;
 if exists(select 1 from public.friendships where (user_a=least(uid,target) and user_b=greatest(uid,target))) then raise exception '已经是好友'; end if;
 insert into public.friend_requests(sender,receiver) values(uid,target)
 on conflict(sender,receiver) do update set status='pending',created_at=now();
 return jsonb_build_object('ok',true);
end; $$;

create or replace function public.accept_friend_request(p_request_id uuid) returns jsonb language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid(); r public.friend_requests%rowtype;
begin
 if uid is null then raise exception '请先登录'; end if;
 select * into r from public.friend_requests where id=p_request_id and receiver=uid and status='pending' for update;
 if r.id is null then raise exception '申请不存在或已处理'; end if;
 update public.friend_requests set status='accepted' where id=r.id;
 insert into public.friendships(user_a,user_b) values(least(r.sender,r.receiver),greatest(r.sender,r.receiver)) on conflict do nothing;
 return jsonb_build_object('ok',true);
end; $$;

create or replace function public.send_chat_message(p_body text,p_friend_id uuid default null) returns jsonb language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid(); clean text:=trim(p_body); pair uuid[];
begin
 if uid is null then raise exception '请先登录'; end if;
 if clean is null or char_length(clean)<1 or char_length(clean)>500 then raise exception '消息长度需为1至500字'; end if;
 if p_friend_id is null then
  insert into public.messages(sender_id,room,participants,body) values(uid,'lobby','{}',clean);
 else
  if not exists(select 1 from public.friendships where user_a=least(uid,p_friend_id) and user_b=greatest(uid,p_friend_id)) then raise exception '只能向好友私聊'; end if;
  pair:=array[uid,p_friend_id];
  insert into public.messages(sender_id,room,participants,body) values(uid,'dm',pair,clean);
 end if;
 return jsonb_build_object('ok',true);
end; $$;

-- The browser sends only game + bet. Outcomes and payout are generated by Postgres.
-- Games are entertainment-only virtual coins, not redeemable for cash.
create or replace function public.play_game(p_game text,p_bet bigint) returns jsonb language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid(); p public.profiles%rowtype; roll double precision; mult numeric; returned bigint; delta bigint; detail text;
begin
 if uid is null then raise exception '请先登录'; end if;
 if p_game not in ('blackjack','slots','wheel') then raise exception '此游戏暂不支持服务器结算'; end if;
 if p_bet is null or p_bet<100 or p_bet>1000000 then raise exception '下注必须在100至1,000,000游戏币之间'; end if;
 select * into p from public.profiles where id=uid for update;
 if p.coins<p_bet then raise exception '游戏币不足'; end if;
 roll:=random();
 if p_game='slots' then
   if roll<0.04 then mult:=5; detail:='三个相同图案'; elsif roll<0.24 then mult:=1.5; detail:='两个相同图案'; else mult:=0; detail:='没有中奖'; end if;
 elsif p_game='wheel' then
   if roll<0.30 then mult:=0; elsif roll<0.50 then mult:=0.5; elsif roll<0.72 then mult:=1; elsif roll<0.88 then mult:=2; elsif roll<0.97 then mult:=3; else mult:=5; end if;
   detail:='大转盘随机奖项：'||mult||'倍';
 else
   -- Server-simulated blackjack result: server chooses a bounded multiplier as the outcome.
   if roll<0.42 then mult:=2; detail:='服务器模拟：玩家获胜'; elsif roll<0.50 then mult:=1; detail:='服务器模拟：平局'; else mult:=0; detail:='服务器模拟：庄家获胜'; end if;
 end if;
 returned:=floor(p_bet*mult); delta:=returned-p_bet;
 update public.profiles set coins=coins-p_bet+returned,
 total_won=total_won+greatest(delta,0), total_lost=total_lost+greatest(-delta,0) where id=uid;
 insert into public.game_history(user_id,game,bet,delta,detail) values(uid,p_game,p_bet,delta,detail);
 return jsonb_build_object('game',p_game,'bet',p_bet,'multiplier',mult,'returned',returned,'delta',delta,'message',detail||'；净变化 '||delta||' 游戏币');
end; $$;

revoke all on function public.claim_allowance() from public;
revoke all on function public.take_loan() from public;
revoke all on function public.send_friend_request(text) from public;
revoke all on function public.accept_friend_request(uuid) from public;
revoke all on function public.send_chat_message(text,uuid) from public;
revoke all on function public.play_game(text,bigint) from public;
grant execute on function public.claim_allowance() to authenticated;
grant execute on function public.take_loan() to authenticated;
grant execute on function public.send_friend_request(text) to authenticated;
grant execute on function public.accept_friend_request(uuid) to authenticated;
grant execute on function public.send_chat_message(text,uuid) to authenticated;
grant execute on function public.play_game(text,bigint) to authenticated;

grant select on public.leaderboard to authenticated;
grant select on public.friend_view to authenticated;
grant select on public.friend_requests_inbox to authenticated;
grant select on public.profiles to authenticated;
grant select on public.messages to authenticated;
grant select on public.friend_requests to authenticated;
grant select on public.friendships to authenticated;
grant select on public.game_history to authenticated;

-- Enable Realtime for live chat updates.
alter publication supabase_realtime add table public.messages;
