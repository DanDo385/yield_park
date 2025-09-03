import { ethers } from "ethers";
import TierVault from "../abi/TierVault.json";
import type { Allocation } from "../types";

export async function pushWeights(
  rpcUrl: string,
  pk: string,
  vaultAddr: string,
  allocations: Allocation[]
) {
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(pk, provider);
  const vault = new ethers.Contract(vaultAddr, TierVault, wallet);

  const adapters = allocations.map(a => a.adapter);
  const bps = allocations.map(a => a.weightBps);
  // NOTE: In demo we use placeholder adapter addresses.
  // In real use, supply real adapters already whitelisted in StrategyRegistry.

  const tx = await vault.setTargetWeights(adapters, bps);
  await tx.wait();
  const rb = await vault.rebalance();
  await rb.wait();
}
