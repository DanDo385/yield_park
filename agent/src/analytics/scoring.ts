import { PoolMetric } from "../types";

/** Simple risk score 0-100 (lower safer). Tune weights per tier. */
export function scoreRisk(p: PoolMetric, opts?: {stableBias?: boolean}) {
  const stable = p.symbol.toUpperCase().includes("USD") || p.symbol.toUpperCase().includes("DAI");
  const assetRisk = (opts?.stableBias && stable) ? 15 : (stable ? 25 : 55);
  const tvlRisk = p.tvlUsd > 100_000_000 ? 10 : p.tvlUsd > 10_000_000 ? 20 : 35;
  const apyRisk = p.apy > 0.15 ? 35 : p.apy > 0.08 ? 25 : 15;
  const protoRisk = 20; // TODO: integrate audits/age/bounty data
  const total = assetRisk + tvlRisk + apyRisk + protoRisk;
  return Math.max(0, Math.min(100, total));
}

export function netUtility(p: PoolMetric) {
  // Example objective = expected APR * (1 - risk/100)
  return p.apy * (1 - p.riskScore / 100);
}
