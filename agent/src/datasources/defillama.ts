import axios from "axios";
import { z } from "zod";

const Pool = z.object({
  pool: z.string(),
  project: z.string(),
  chain: z.string(),
  symbol: z.string().optional().default(""),
  apy: z.number().nullable(),
  tvlUsd: z.number().nullable()
});
type LlamaPool = z.infer<typeof Pool>;

export async function fetchTopStablePools(limit = 20) {
  const res = await axios.get("https://yields.llama.fi/pools");
  const pools = z.array(Pool).parse(res.data.data);
  const filtered = pools
    .filter(p => (p.apy ?? 0) > 0 && (p.tvlUsd ?? 0) > 100000)
    .sort((a, b) => (b.apy ?? 0) - (a.apy ?? 0))
    .slice(0, limit);
  return filtered.map(p => ({
    id: p.pool,
    protocol: p.project,
    chain: p.chain,
    symbol: p.symbol,
    apy: p.apy ?? 0,
    tvlUsd: p.tvlUsd ?? 0,
    riskScore: 50 // placeholder, scored later
  }));
}
