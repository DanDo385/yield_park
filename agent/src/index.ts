import "dotenv/config";
import pino from "pino";
import { fetchTopStablePools } from "./datasources/defillama";
import { scoreRisk, netUtility } from "./analytics/scoring";
import { planAllocations } from "./planner/optimizer";
import { pushWeights } from "./executors/onchain";

const log = pino({ level: "info" });

async function runOnce() {
  const rpc = process.env.RPC_URL!;
  const pk = process.env.PRIVATE_KEY!;
  const gold = process.env.GOLD_VAULT!;
  const silver = process.env.SILVER_VAULT!;
  const bronze = process.env.BRONZE_VAULT!;

  // Demo: just stable pools for all; later customize per tier & asset class
  const pools = await fetchTopStablePools(30);
  const scored = pools.map(p => ({ ...p, riskScore: scoreRisk(p, {stableBias: true}) }))
                      .sort((a,b) => netUtility(b) - netUtility(a));

  const allocGold   = planAllocations(scored, { maxPerAdapterBps: 3000, slots: 2 });
  const allocSilver = planAllocations(scored, { maxPerAdapterBps: 4000, slots: 2 });
  const allocBronze = planAllocations(scored, { maxPerAdapterBps: 2000, slots: 2 });

  log.info({ allocGold, allocSilver, allocBronze }, "Proposed allocations");

  // For the demo, adapters are placeholders. Skip pushWeights unless you've set real adapter addrs.
  if (process.env.PUSH_TX === "true") {
    await pushWeights(rpc, pk, gold, allocGold);
    await pushWeights(rpc, pk, silver, allocSilver);
    await pushWeights(rpc, pk, bronze, allocBronze);
  }
}

runOnce().catch((e) => {
  console.error(e);
  process.exit(1);
});
