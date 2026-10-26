# Lucky Arcade — deployable starter

This is a Next.js + Supabase starter for a public, multi-user virtual-coin game hall.

## Included
- Supabase email/password authentication and profile creation trigger
- PostgreSQL persistent profiles, virtual coin balances, loan balance, and game history
- Server-side allowance and loan RPCs
- Server-side random payouts for slots, wheel, and a simulated blackjack outcome
- Friend requests and accepted friendships
- Lobby chat and friend-only direct message table with RLS
- Realtime message refresh
- Leaderboard
- Practice-mode Tic-Tac-Toe, Rock-Paper-Scissors UI, and memory cards

## Important limitation
The included blackjack payout is a server-side simulated result, **not a card-by-card blackjack implementation**. Tic-tac-toe, rock-paper-scissors, and memory are currently practice modes and do not award coins. Before calling this a finished production game, implement server-authoritative state/validation for those games, add chat moderation/rate limits, and perform security testing. All currency is virtual, with no deposits or cash-out.

## 1. Create Supabase project
1. Go to https://supabase.com and sign up.
2. Create a new project; save the database password somewhere safe.
3. In the project's SQL Editor, paste and run all of `supabase/schema.sql`.
4. In Project Settings / API (or Connect), copy the Project URL and publishable/anon key.
5. In Authentication settings, enable email/password. For easy testing you may disable email confirmation; for a public site, keep email confirmation on and configure SMTP as needed.
6. In Authentication URL configuration, set the Site URL to your eventual Vercel URL after deployment.

## 2. Create GitHub repository
1. Go to https://github.com and create a free account.
2. Create a new repository named `lucky-arcade`.
3. Upload all files in this folder, preserving the folder structure. You can upload files through GitHub's web UI, or extract the ZIP on a computer and push it with Git.
4. Do not upload `.env.local` or any secret key.

## 3. Deploy to Vercel
1. Go to https://vercel.com and sign up using GitHub.
2. Choose Add New → Project, import `lucky-arcade`.
3. Add Environment Variables:
   - `NEXT_PUBLIC_SUPABASE_URL` = your Supabase Project URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = your Supabase publishable/anon key
4. Click Deploy. Vercel gives you a `*.vercel.app` URL.
5. In Supabase Auth URL configuration, set Site URL to that URL. Add it to Redirect URLs if prompted.
6. Test registration with two separate accounts/browsers.

## 4. Local run (optional)
- Install Node.js 20+ from https://nodejs.org
- Copy `.env.example` to `.env.local` and fill in the Supabase values.
- Run `npm install`, then `npm run dev`.
- Visit http://localhost:3000

## Security notes
- Never put a Supabase service-role key in `NEXT_PUBLIC_*` variables or browser code.
- SQL functions use `auth.uid()` and `SECURITY DEFINER`; keep the function grants and RLS policies.
- The current UI is a starter, not a fully audited production service. Add rate limiting, moderation, abuse reporting, email verification, backups, and privacy/terms pages before inviting a large public audience.
