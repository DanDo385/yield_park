import { Providers } from "../lib/wagmi";
import TierCard from "../components/TierCard";

const GOLD = process.env.NEXT_PUBLIC_GOLD_VAULT as `0x${string}`;
const SILVER = process.env.NEXT_PUBLIC_SILVER_VAULT as `0x${string}`;
const BRONZE = process.env.NEXT_PUBLIC_BRONZE_VAULT as `0x${string}`;

export default function Page() {
  return (
    <Providers>
      <main className="max-w-5xl mx-auto p-6 space-y-6">
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold text-slate-900">Yield Park</h1>
          <p className="text-lg text-slate-600">DeFi Yield Tiers - Gold, Silver, Bronze</p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <TierCard name="Gold" address={GOLD} decimals={6} />
          <TierCard name="Silver" address={SILVER} decimals={6} />
          <TierCard name="Bronze" address={BRONZE} decimals={18} />
        </div>
        
        <div className="bg-white rounded-2xl shadow p-6 space-y-4">
          <h2 className="text-xl font-semibold">About Yield Park</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            <div>
              <h3 className="font-semibold text-yellow-600">Gold Tier (4-6% APY)</h3>
              <p className="text-slate-600">Safest, stablecoin-only strategies with fiat-backed assets and Maker DSR integration.</p>
            </div>
            <div>
              <h3 className="font-semibold text-gray-500">Silver Tier (6-10% APY)</h3>
              <p className="text-slate-600">Moderate risk with boosted stablecoin strategies and incentive rotations.</p>
            </div>
            <div>
              <h3 className="font-semibold text-amber-600">Bronze Tier (10-25%+ APY)</h3>
              <p className="text-slate-600">Highest risk with LSTs, LRTs, and volatile yield farming strategies.</p>
            </div>
          </div>
        </div>
        
        <p className="text-sm text-slate-500 text-center">
          Demo uses mock tokens/adapters. For production, plug in real adapters and prices, and
          remove the baseline override buttons.
        </p>
      </main>
    </Providers>
  );
}
