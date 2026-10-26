export default function Home() {
  return (
    <main style={{ padding: 30, fontFamily: "Arial", color: "white", background: "#111", minHeight: "100vh" }}>
      <h1>🎰 Lucky Arcade</h1>
      <p>欢迎来到幸运街机！</p>
      <p>虚拟金币游戏大厅</p>
    </main>
  );
}
"use client";

import { useState } from "react";

const games = [
{ name: "老虎机", icon: "🎰", color: "#7c3aed", desc: "试试你的运气" },
{ name: "幸运转盘", icon: "🎡", color: "#db2777", desc: "转出幸运奖励" },
{ name: "二十一点", icon: "🃏", color: "#0891b2", desc: "挑战你的策略" },
{ name: "剪刀石头布", icon: "✂️", color: "#ea580c", desc: "与你的运气对决" },
{ name: "井字棋", icon: "⭕", color: "#059669", desc: "动动脑筋" },
{ name: "记忆翻牌", icon: "🧠", color: "#4f46e5", desc: "考验你的记忆" },
];

export default function Home() {
const [coins, setCoins] = useState(10000);
const [notice, setNotice] = useState("欢迎来到 Lucky Arcade！");
const [activeGame, setActiveGame] = useState("");

function playGame(name: string) {
setActiveGame(name);
setNotice("${name} 即将开放，敬请期待！");
}

return (
<main style={{ minHeight: "100vh", background: "#0b1020", color: "white", fontFamily: "Arial, sans-serif", padding: "24px", boxSizing: "border-box" }}>
<header style={{ maxWidth: 1100, margin: "0 auto", display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 16 }}>
<div>
<div style={{ fontSize: 13, letterSpacing: 3, color: "#a78bfa" }}>WELCOME TO</div>
<h1 style={{ fontSize: 32, margin: "6px 0" }}>🎮 Lucky Arcade</h1>
<div style={{ color: "#aab3ca" }}>你的线上小游戏大厅</div>
</div>
<div style={{ background: "#171f36", border: "1px solid #35405d", borderRadius: 16, padding: "14px 20px" }}>
<div style={{ color: "#aab3ca", fontSize: 13 }}>我的虚拟金币</div>
<div style={{ fontSize: 26, fontWeight: 800, color: "#fbbf24" }}>🪙 {coins.toLocaleString()}</div>
</div>
</header>

  <section style={{ maxWidth: 1100, margin: "32px auto 0", background: "linear-gradient(120deg,#312e81,#6d28d9)", borderRadius: 22, padding: 24 }}>
    <div style={{ color: "#ddd6fe", fontSize: 13, fontWeight: 700 }}>LUCKY BONUS</div>
    <h2 style={{ fontSize: 25, margin: "10px 0" }}>好运每天都可能发生 ✨</h2>
    <p style={{ color: "#ede9fe", lineHeight: 1.6 }}>使用虚拟金币体验小游戏。仅供娱乐，不涉及真钱交易。</p>
    <button onClick={() => { setCoins(c => c + 50000); setNotice("已领取 50,000 枚演示金币！"); }} style={{ background: "#fbbf24", color: "#241400", border: 0, borderRadius: 12, padding: "12px 18px", fontWeight: 800, fontSize: 15 }}>
      + 领取 50,000 演示金币
    </button>
  </section>

  <section style={{ maxWidth: 1100, margin: "32px auto" }}>
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "end", gap: 12, flexWrap: "wrap", marginBottom: 18 }}>
      <div>
        <h2 style={{ margin: 0, fontSize: 24 }}>🎯 游戏大厅</h2>
        <p style={{ color: "#aab3ca", marginBottom: 0 }}>选择你想玩的游戏</p>
      </div>
      <div style={{ color: "#aab3ca", fontSize: 13 }}>共 {games.length} 款游戏</div>
    </div>

    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(230px,1fr))", gap: 16 }}>
      {games.map(game => (
        <button key={game.name} onClick={() => playGame(game.name)} style={{ textAlign: "left", background: "#151d32", color: "white", border: "1px solid #2c3854", borderRadius: 18, padding: 20, cursor: "pointer" }}>
          <div style={{ width: 54, height: 54, borderRadius: 15, background: game.color, display: "grid", placeItems: "center", fontSize: 29 }}>{game.icon}</div>
          <h3 style={{ margin: "16px 0 6px", fontSize: 19 }}>{game.name}</h3>
          <div style={{ color: "#aab3ca", fontSize: 14 }}>{game.desc}</div>
          <div style={{ marginTop: 18, color: "#c4b5fd", fontWeight: 700 }}>进入游戏 →</div>
        </button>
      ))}
    </div>
  </section>

  <section style={{ maxWidth: 1100, margin: "0 auto", background: "#151d32", border: "1px solid #2c3854", borderRadius: 18, padding: 20 }}>
    <h2 style={{ marginTop: 0 }}>🏆 排行榜</h2>
    <p style={{ color: "#aab3ca" }}>玩家排行榜将在连接数据库后显示。</p>
    <h2>💬 好友与聊天</h2>
    <p style={{ color: "#aab3ca" }}>好友申请、公共聊天室和私聊功能将在下一阶段连接。</p>
  </section>

  <footer style={{ maxWidth: 1100, margin: "24px auto 0", color: "#68738f", fontSize: 12, textAlign: "center" }}>
    Lucky Arcade · 虚拟金币仅供娱乐 · 不涉及真钱交易
  </footer>

  {notice && (
    <div role="status" style={{ position: "fixed", bottom: 18, left: "50%", transform: "translateX(-50%)", background: "#f8fafc", color: "#111827", padding: "12px 18px", borderRadius: 12, boxShadow: "0 8px 30px #0006", maxWidth: "90%", textAlign: "center" }}>
      {notice}
      <button onClick={() => setNotice("")} style={{ marginLeft: 12, border: 0, background: "transparent", fontWeight: 800 }}>✕</button>
    </div>
  )}

  {activeGame && (
    <div role="dialog" aria-modal="true" style={{ position: "fixed", inset: 0, background: "#000b", display: "grid", placeItems: "center", padding: 20 }}>
      <div style={{ background: "#151d32", border: "1px solid #35405d", borderRadius: 18, padding: 24, maxWidth: 360, width: "100%" }}>
        <h2>{activeGame}</h2>
        <p style={{ color: "#aab3ca" }}>这个游戏还没有接入实际玩法。</p>
        <button onClick={() => setActiveGame("")} style={{ background: "#7c3aed", color: "white", border: 0, borderRadius: 10, padding: "10px 16px" }}>返回大厅</button>
      </div>
    </div>
  )
