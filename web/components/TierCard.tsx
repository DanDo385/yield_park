"use client";

import React, { useEffect, useState } from "react";
import { formatUnits } from "viem";
import { useReadContract } from "wagmi";
import TierVaultAbi from "../lib/abi/TierVault";

type Props = { name: string; address: `0x${string}`; decimals: number };

export default function TierCard({ name, address, decimals }: Props) {
  const { data: totalAssets } = useReadContract({
    address,
    abi: TierVaultAbi,
    functionName: "totalAssets"
  });
  const [baseline, setBaseline] = useState<number>(() => {
    const k = `baseline-${address}`;
    const v = typeof window !== "undefined" ? window.localStorage.getItem(k) : null;
    return v ? Number(v) : 1000; // $1,000 baseline for display
  });

  useEffect(() => {
    const k = `baseline-${address}`;
    window.localStorage.setItem(k, String(baseline));
  }, [address, baseline]);

  const tvl = totalAssets ? Number(formatUnits(totalAssets as bigint, decimals)) : 0;
  const pnl = tvl - baseline;
  const pnlPct = baseline > 0 ? (pnl / baseline) * 100 : 0;

  return (
    <div className="rounded-2xl shadow bg-white p-6 space-y-2">
      <h2 className="text-xl font-semibold">{name}</h2>
      <p className="text-sm text-slate-500 break-all">{address}</p>
      <div className="text-3xl font-bold">${tvl.toFixed(2)}</div>
      <div className={pnl >= 0 ? "text-green-600" : "text-red-600"}>
        P&L: ${pnl.toFixed(2)} ({pnlPct.toFixed(2)}%)
      </div>
      <div className="flex items-center gap-2">
        <button
          className="px-3 py-1 rounded bg-slate-100"
          onClick={() => setBaseline(tvl)}
          title="Set current value as baseline (acts like 'I deposited $1,000 here')"
        >
          Set Baseline = Current
        </button>
        <button className="px-3 py-1 rounded bg-slate-100" onClick={() => setBaseline(1000)}>
          Reset to $1,000
        </button>
      </div>
    </div>
  );
}
