import "./globals.css";
import React from "react";

export const metadata = {
  title: "Yield Park - DeFi Yield Tiers",
  description: "Gold / Silver / Bronze yield vaults with automated rebalancing"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-slate-50 text-slate-900">{children}</body>
    </html>
  );
}
