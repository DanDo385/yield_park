// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategyAdapter} from "../interfaces/IStrategyAdapter.sol";

/**
 * @title UniswapV3LPAdapter (stub)
 * @notice Manages a single concentrated-liquidity position for (asset, otherToken).
 *         Very simplified accounting: tracks notional "total" (deposits - withdrawals).
 *         In production, compute value from position liquidity + pool price, and handle fees.
 *
 * Constructor:
 *  - asset_         : ERC20 underlying used by the vault (e.g., USDC)
 *  - otherToken_    : paired token (e.g., WETH)
 *  - vault_         : TierVault allowed to call deposit/withdraw
 *  - router_        : Uniswap v3 ISwapRouter
 *  - posm_          : Uniswap v3 NonfungiblePositionManager
 *  - fee_           : pool fee (e.g., 500, 3000, 10000)
 *  - tickLower_/Upper_: chosen ticks (stub: pass in fixed range, e.g., +/- 1% band)
 *
 * WARNING (stub):
 *  - totalAssets() uses internal tracker; replace with real valuation from position.
 *  - No auto-compound; no fee collection automation.
 */
contract UniswapV3LPAdapter is IStrategyAdapter {
    using SafeERC20 for IERC20;

    IERC20 public immutable u;           // underlying (e.g., USDC)
    IERC20 public immutable other;       // other token (e.g., WETH)
    address public immutable vault;
    ISwapRouter public immutable router;
    INonfungiblePositionManager public immutable posm;
    uint24 public immutable fee;
    int24 public immutable tickLower;
    int24 public immutable tickUpper;

    uint256 public tokenId;              // NFT position id (0 until minted)
    uint256 public total;                // STUB accounting of underlying value (in `u` units)

    modifier onlyVault() {
        require(msg.sender == vault, "UniV3Adapter: only vault");
        _;
    }

    constructor(
        IERC20 asset_,
        IERC20 otherToken_,
        address vault_,
        address router_,
        address posm_,
        uint24 fee_,
        int24 tickLower_,
        int24 tickUpper_
    ) {
        u = asset_;
        other = otherToken_;
        vault = vault_;
        router = ISwapRouter(router_);
        posm = INonfungiblePositionManager(posm_);
        fee = fee_;
        tickLower = tickLower_;
        tickUpper = tickUpper_;
    }

    // -------- IStrategyAdapter --------
    function asset() external view returns (address) { return address(u); }

    function totalAssets() public view returns (uint256) {
        // STUB: track deposits - withdrawals.
        // TODO(prod): read position liquidity, quote amounts at current sqrtPriceX96, add fees owed.
        return total;
    }

    function currentApr() external pure returns (uint256) {
        // No APR oracle for LP fees; compute off-chain or via stats. Return 0 here.
        return 0;
    }

    function deposit(uint256 assets) external onlyVault returns (uint256) {
        // Pull underlying from vault
        u.safeTransferFrom(msg.sender, address(this), assets);

        // 1) Swap ~50% of `u` to `other` (stub exactInputSingle with naive split & slippage)
        uint256 half = assets / 2;
        if (half > 0) {
            u.approve(address(router), 0);
            u.approve(address(router), half);
            ISwapRouter.ExactInputSingleParams memory p = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(u),
                tokenOut: address(other),
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 600,
                amountIn: half,
                amountOutMinimum: (half * 9950) / 10000, // 0.5% slippage stub, TODO: use oracle
                sqrtPriceLimitX96: 0
            });
            router.exactInputSingle(p);
        }

        // 2) Mint or increase position with balances on hand
        u.approve(address(posm), 0);
        other.approve(address(posm), 0);
        u.approve(address(posm), type(uint256).max);
        other.approve(address(posm), type(uint256).max);

        if (tokenId == 0) {
            INonfungiblePositionManager.MintParams memory mp = INonfungiblePositionManager.MintParams({
                token0: address(u) < address(other) ? address(u) : address(other),
                token1: address(u) < address(other) ? address(other) : address(u),
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: address(u) < address(other) ? u.balanceOf(address(this)) : other.balanceOf(address(this)),
                amount1Desired: address(u) < address(other) ? other.balanceOf(address(this)) : u.balanceOf(address(this)),
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 600
            });
            (tokenId,,,) = posm.mint(mp);
        } else {
            INonfungiblePositionManager.IncreaseLiquidityParams memory ip = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: address(u) < address(other) ? u.balanceOf(address(this)) : other.balanceOf(address(this)),
                amount1Desired: address(u) < address(other) ? other.balanceOf(address(this)) : u.balanceOf(address(this)),
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 600
            });
            posm.increaseLiquidity(ip);
        }

        total += assets; // STUB: optimistic accounting
        return total;
    }

    function withdraw(uint256 assets) external onlyVault returns (uint256) {
        // STUB approach: proportionally remove liquidity to realize `assets` of `u`.
        // In practice you should price the position and remove appropriate liquidity.
        require(tokenId != 0, "no-position");
        uint128 liqToBurn = 0; // TODO(prod): compute proportion from position.liquidity

        // Decrease liquidity (stub minimal)
        INonfungiblePositionManager.DecreaseLiquidityParams memory dp =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liqToBurn,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 600
            });
        posm.decreaseLiquidity(dp);

        // Collect tokens owed
        INonfungiblePositionManager.CollectParams memory cp =
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        posm.collect(cp);

        // Swap `other` back to `u` as needed (best-effort)
        uint256 otherBal = other.balanceOf(address(this));
        if (otherBal > 0) {
            other.approve(address(router), 0);
            other.approve(address(router), otherBal);
            ISwapRouter.ExactInputSingleParams memory p = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(other),
                tokenOut: address(u),
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 600,
                amountIn: otherBal,
                amountOutMinimum: (otherBal * 9900) / 10000, // 1% stub
                sqrtPriceLimitX96: 0
            });
            router.exactInputSingle(p);
        }

        uint256 out = u.balanceOf(address(this));
        if (assets < out) out = assets; // send up to requested
        u.safeTransfer(msg.sender, out);

        // STUB: decrease accounting
        if (out > total) { total = 0; } else { total -= out; }
        return out;
    }

    function harvest() external onlyVault {
        // Optional: collect fees without changing liquidity; add to 'total'.
        if (tokenId != 0) {
            INonfungiblePositionManager.CollectParams memory cp =
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                });
            posm.collect(cp);
        }
        emit Harvest(0, 0);
    }
}

/* ---------- Minimal Uniswap v3 interfaces ---------- */
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0; address token1; uint24 fee; int24 tickLower; int24 tickUpper;
        uint256 amount0Desired; uint256 amount1Desired;
        uint256 amount0Min; uint256 amount1Min; address recipient; uint256 deadline;
    }
    struct IncreaseLiquidityParams {
        uint256 tokenId; uint256 amount0Desired; uint256 amount1Desired; uint256 amount0Min; uint256 amount1Min; uint256 deadline;
    }
    struct DecreaseLiquidityParams {
        uint256 tokenId; uint128 liquidity; uint256 amount0Min; uint256 amount1Min; uint256 deadline;
    }
    struct CollectParams {
        uint256 tokenId; address recipient; uint128 amount0Max; uint128 amount1Max;
    }
    function mint(MintParams calldata params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);
    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}
