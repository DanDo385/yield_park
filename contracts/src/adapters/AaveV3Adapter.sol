// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { IStrategyAdapter } from "../interfaces/IStrategyAdapter.sol";

/**
 * @title AaveV3Adapter
 * @notice Supplies underlying to Aave v3 and holds aTokens in this adapter.
 *         totalAssets() = aToken.balanceOf(this) (1:1 with underlying, accrues interest)
 *
 * Constructor args:
 *  - asset_   : the underlying ERC20 this vault uses (e.g., USDC)
 *  - vault_   : the TierVault address allowed to call deposit/withdraw (only-vault)
 *  - pool_    : Aave v3 IPool address (per chain)
 *  - aToken_  : the corresponding aToken for underlying (per asset/chain)
 *
 * Notes:
 *  - currentApr() best-effort via getReserveData().currentLiquidityRate (ray -> 1e18).
 *  - Rewards (LM) are NOT claimed here; wire a separate harvester if needed.
 */
contract AaveV3Adapter is IStrategyAdapter {
    using SafeERC20 for IERC20;

    IERC20 public immutable u;
    address public immutable vault;
    IAavePool public immutable pool;
    IERC20 public immutable aToken;

    modifier onlyVault() {
        require(msg.sender == vault, "AaveV3Adapter: only vault");
        _;
    }

    constructor(IERC20 asset_, address vault_, address pool_, IERC20 aToken_) {
        u = asset_;
        vault = vault_;
        pool = IAavePool(pool_);
        aToken = aToken_;
    }

    // ===== IStrategyAdapter =====
    function asset() external view returns (address) { return address(u); }

    function totalAssets() public view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function currentApr() external view returns (uint256) {
        // Aave v3 liquidity rate is in ray (1e27) as an APR.
        // Convert to 1e18 for consistency with the rest of the system.
        try pool.getReserveData(address(u)) returns (ReserveData memory d) {
            return uint256(d.currentLiquidityRate) / 1e9; // 1e27 -> 1e18
        } catch {
            return 0;
        }
    }

    function deposit(uint256 assets) external onlyVault returns (uint256) {
        // Pull underlying from the vault (vault pre-approves adapter)
        u.safeTransferFrom(msg.sender, address(this), assets);
        // Approve and supply to Aave
        u.approve(address(pool), 0);
        u.approve(address(pool), assets);
        pool.supply(address(u), assets, address(this), 0);
        return aToken.balanceOf(address(this));
    }

    function withdraw(uint256 assets) external onlyVault returns (uint256) {
        // Withdraw underlying directly to the vault (Aave returns actual amount withdrawn)
        uint256 out = pool.withdraw(address(u), assets, msg.sender);
        return out;
    }

    function harvest() external onlyVault {
        // No-op: interest accrues in aToken exchange rate.
        // Rewards claiming is out-of-scope here. Emit an informative event.
        emit Harvest(0, 0);
    }
}

/* -------------------- Minimal Aave v3 interfaces -------------------- */

struct ReserveConfigurationMap { uint256 data; }

struct ReserveData {
    ReserveConfigurationMap configuration;
    uint128 liquidityIndex;
    uint128 currentLiquidityRate;
    uint128 variableBorrowIndex;
    uint128 currentVariableBorrowRate;
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    uint8 id;
}

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function getReserveData(address asset) external view returns (ReserveData memory);
}
