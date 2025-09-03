export type VaultConfig = {
  name: "gold" | "silver" | "bronze";
  address: string;
  targetMaxPerAdapterBps: number;
  targetMaxShiftBps: number;
};

export type PoolMetric = {
  id: string;
  protocol: string;
  chain: string;
  symbol: string;
  apy: number; // decimal (e.g., 0.08 = 8%)
  tvlUsd: number;
  riskScore: number; // 0-100 (lower is safer)
};

export type Allocation = {
  adapter: string;
  weightBps: number;
  reason: string;
};
