// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { IStrategyAdapter } from "../interfaces/IStrategyAdapter.sol";

/**
 * @title CompoundV3Adapter (Comet)
 * @notice Supplies/withdraws the base asset in a Comet market.
 *
 * Constructor args:
 *  - asset_  : underlying ERC20 (e.g., USDC)
 *  - vault_  : TierVault address
 *  - comet_  : Comet (Compound v3) market address for the asset
 *
 * totalAssets():
 *  - **Stub mode**: we keep an internal `total` tracker updated on deposits/withdrawals.
 *    (Replace with Comet's precise accounting if you prefer on-chain read:
 *     e.g., `comet.balanceOf(address(this))` or `comet.userBasic(address(this))` math.)
 *
 * currentApr():
 *  - Optional/Best-effort: tries `getUtilization()` + `getSupplyRate(util)`.
 *    If interface not present on a given deployment, returns 0.
 */
contract CompoundV3Adapter is IStrategyAdapter {
    using SafeERC20 for IERC20;

    IERC20 public immutable u;
    address public immutable vault;
    IComet public immutable comet;

    uint256 public total; // stub tracker; replace with precise on-chain reading if desired

    modifier onlyVault() {
        require(msg.sender == vault, "CompoundV3Adapter: only vault");
        _;
    }

    constructor(IERC20 asset_, address vault_, address comet_) {
        u = asset_;
        vault = vault_;
        comet = IComet(comet_);
    }

    // ===== IStrategyAdapter =====
    function asset() external view returns (address) { return address(u); }

    function totalAssets() public view returns (uint256) {
        // If your Comet exposes a reliable "balance" view you trust, prefer that over `total`.
        // try comet.balanceOf(address(this)) returns (uint256 bal) { return bal; } catch {}
        return total;
    }

    function currentApr() external view returns (uint256) {
        // Best-effort APR probing (per-second rate * 365 days)
        try comet.getUtilization() returns (uint64 util) {
            try comet.getSupplyRate(util) returns (uint64 perSecRate) {
                // perSecRate expected in 1e18 scale per second
                return uint256(perSecRate) * 365 days;
            } catch { return 0; }
        } catch { return 0; }
    }

    function deposit(uint256 assets) external onlyVault returns (uint256) {
        u.safeTransferFrom(msg.sender, address(this), assets);
        u.approve(address(comet), 0);
        u.approve(address(comet), assets);
        comet.supply(address(u), assets);
        total += assets; // stub: optimistic accounting
        return total;
    }

    function withdraw(uint256 assets) external onlyVault returns (uint256) {
        comet.withdraw(address(u), assets); // sends underlying to this adapter
        u.safeTransfer(msg.sender, assets);
        if (assets > total) { total = 0; } else { total -= assets; }
        return assets;
    }

    function harvest() external onlyVault {
        emit Harvest(0, 0); // interest accrues inside Comet; no-op here
    }
}

/* -------------------- Minimal Comet (Compound v3) interface -------------------- */

interface IComet {
    function supply(address asset, uint amount) external;
    function withdraw(address asset, uint amount) external;
    // Optional views (available on many Comet deployments):
    function getUtilization() external view returns (uint64);
    function getSupplyRate(uint64 utilization) external view returns (uint64);
    // Some deployments also expose `balanceOf(address)`; if so, prefer that to track totalAssets.
    // function balanceOf(address) external view returns (uint256);
}
