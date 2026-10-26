import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "Lucky Arcade", description: "多人在线虚拟币小游戏厅" };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="zh-CN"><body>{children}</body></html>; }