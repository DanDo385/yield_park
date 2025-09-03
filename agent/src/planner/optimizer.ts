import { PoolMetric, Allocation } from "../types";

/** Pick top-N candidates under simple concentration caps; return weights */
export function planAllocations(
  pools: PoolMetric[],
  opts: { maxPerAdapterBps: number; slots: number }
): Allocation[] {
  const sorted = [...pools].sort((a,b) => (b.apy*(1-b.riskScore/100)) - (a.apy*(1-a.riskScore/100)));
  const take = sorted.slice(0, opts.slots);
  const w = Math.floor(10000 / take.length);
  return take.map(p => ({
    adapter: `0xADAPTER_${p.protocol}_${p.symbol.replace(/[^A-Za-z0-9]/g,"").slice(0,8)}`,
    weightBps: Math.min(w, opts.maxPerAdapterBps),
    reason: `Chosen by utility score; APY=${(p.apy*100).toFixed(2)}% risk=${p.riskScore}`
  }));
}
