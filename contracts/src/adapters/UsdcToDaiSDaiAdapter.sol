// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategyAdapter} from "../interfaces/IStrategyAdapter.sol";

/**
 * @title UsdcToDaiSDaiAdapter (stub)
 * @notice Vault asset = USDC. On deposit: swap USDC->DAI via Uniswap v3, then deposit to sDAI (DSR).
 *         On withdraw: redeem sDAI to DAI, swap DAI->USDC, return to vault.
 *
 * Slippage:
 *  - Uses `slippageBps` (e.g., 50 = 0.5%) against a naive 1:1 expectation as a STUB.
 *  - TODO: integrate a PriceRouter or TWAP oracle to set sensible minOut values.
 *
 * Constructor:
 *  - usdc_       : USDC token (vault asset)
 *  - dai_        : DAI token
 *  - sDai_       : sDAI (ERC-4626) address
 *  - vault_      : TierVault
 *  - router_     : Uniswap v3 ISwapRouter
 *  - poolFee_    : USDC/DAI pool fee (e.g., 500)
 *  - slippageBps_: e.g., 50 (0.5%)
 */
contract UsdcToDaiSDaiAdapter is IStrategyAdapter {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;
    IERC20 public immutable dai;
    ISavingsDai public immutable sDai;
    address public immutable vault;
    ISwapRouter public immutable router;
    uint24 public immutable poolFee;
    uint16 public slippageBps;

    modifier onlyVault() {
        require(msg.sender == vault, "USDC->sDAI: only vault");
        _;
    }

    constructor(
        IERC20 usdc_,
        IERC20 dai_,
        address sDai_,
        address vault_,
        address router_,
        uint24 poolFee_,
        uint16 slippageBps_
    ) {
        usdc = usdc_;
        dai = dai_;
        sDai = ISavingsDai(sDai_);
        vault = vault_;
        router = ISwapRouter(router_);
        poolFee = poolFee_;
        slippageBps = slippageBps_;
    }

    // ===== IStrategyAdapter =====
    function asset() external view returns (address) { return address(usdc); }

    function totalAssets() public view returns (uint256) {
        // STUB: assume DAI≈USDC 1:1; convert sDAI shares to DAI, treat as USDC.
        uint256 shares = sDai.balanceOf(address(this));
        try sDai.convertToAssets(shares) returns (uint256 daiAmt) { return daiAmt; }
        catch { return 0; }
    }

    function currentApr() external pure returns (uint256) {
        return 0; // compute off-chain from sDAI share price change or Maker feed
    }

    function deposit(uint256 assets) external onlyVault returns (uint256) {
        // 1) Pull USDC from vault
        usdc.safeTransferFrom(msg.sender, address(this), assets);

        // 2) Swap USDC -> DAI
        usdc.approve(address(router), 0);
        usdc.approve(address(router), assets);
        ISwapRouter.ExactInputSingleParams memory p = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(usdc),
            tokenOut: address(dai),
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp + 600,
            amountIn: assets,
            amountOutMinimum: assets * (10000 - slippageBps) / 10000, // STUB 1:1 ref
            sqrtPriceLimitX96: 0
        });
        uint256 daiOut = router.exactInputSingle(p);

        // 3) Deposit DAI -> sDAI
        dai.approve(address(sDai), 0);
        dai.approve(address(sDai), daiOut);
        uint256 shares = sDai.deposit(daiOut, address(this));
        return shares; // returning "shares" (not strictly required by interface)
    }

    function withdraw(uint256 assets) external onlyVault returns (uint256) {
        // We want `assets` USDC back to vault.
        // 1) Figure out DAI needed; STUB assume 1:1
        uint256 daiNeeded = assets;

        // 2) Redeem sDAI -> DAI
        uint256 shares = sDai.convertToShares(daiNeeded);
        if (sDai.convertToAssets(shares) < daiNeeded) shares += 1;
        uint256 daiOut = sDai.redeem(shares, address(this), address(this));

        // 3) Swap DAI -> USDC
        dai.approve(address(router), 0);
        dai.approve(address(router), daiOut);
        ISwapRouter.ExactInputSingleParams memory p = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(dai),
            tokenOut: address(usdc),
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp + 600,
            amountIn: daiOut,
            amountOutMinimum: daiOut * (10000 - slippageBps) / 10000, // STUB
            sqrtPriceLimitX96: 0
        });
        uint256 usdcOut = router.exactInputSingle(p);

        // 4) Send to vault (cap to requested)
        uint256 out = usdcOut;
        if (out > assets) out = assets;
        usdc.safeTransfer(msg.sender, out);
        return out;
    }

    function harvest() external onlyVault {
        emit Harvest(0, 0); // sDAI accrues in share price; swaps realized on rebalance/withdraw
    }

    // Optional: let manager tune slippage
    function setSlippageBps(uint16 bps) external onlyVault { // tighten to MANAGER in prod
        require(bps <= 300, "slippage too high"); // ≤3% guard
        slippageBps = bps;
    }
}

/* ---- Minimal interfaces ---- */
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

interface ISavingsDai {
    // ERC20
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);

    // ERC4626
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
}
