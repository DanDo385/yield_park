// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategyAdapter} from "../interfaces/IStrategyAdapter.sol";

/**
 * @title PendleSYAdapter (stub)
 * @notice Wraps a Pendle SY token (many behave like ERC-4626) for a single underlying.
 *         If your SY is not ERC-4626-like, replace with the correct interface calls.
 *
 * Constructor:
 *  - asset_ : underlying (e.g., USDC)
 *  - vault_ : TierVault
 *  - sy_    : Pendle SY token (target wrapper)
 *
 * Notes:
 *  - totalAssets() uses SY.convertToAssets(balanceOf(this)) where available.
 *  - currentApr() returns 0 (compute off-chain; Pendle markets expose rich analytics).
 */
contract PendleSYAdapter is IStrategyAdapter {
    using SafeERC20 for IERC20;

    IERC20 public immutable u;
    ISY public immutable sy;
    address public immutable vault;

    modifier onlyVault() {
        require(msg.sender == vault, "PendleSYAdapter: only vault");
        _;
    }

    constructor(IERC20 asset_, address vault_, address sy_) {
        u = asset_;
        vault = vault_;
        sy = ISY(sy_);
    }

    function asset() external view returns (address) { return address(u); }

    function totalAssets() public view returns (uint256) {
        try sy.convertToAssets(sy.balanceOf(address(this))) returns (uint256 a) { return a; }
        catch { return 0; } // fallback
    }

    function currentApr() external view returns (uint256) { return 0; }

    function deposit(uint256 assets) external onlyVault returns (uint256) {
        u.safeTransferFrom(msg.sender, address(this), assets);
        u.approve(address(sy), 0);
        u.approve(address(sy), assets);
        uint256 shares = sy.deposit(assets, address(this));
        return shares;
    }

    function withdraw(uint256 assets) external onlyVault returns (uint256) {
        uint256 shares = sy.convertToShares(assets);
        // round up 1 share if needed
        if (sy.convertToAssets(shares) < assets) shares += 1;
        uint256 out = sy.redeem(shares, address(this), address(this));
        u.safeTransfer(msg.sender, out);
        return out;
    }

    function harvest() external onlyVault { emit Harvest(0, 0); }
}

/* ---- Minimal ERC4626-like SY interface (adjust per actual SY) ---- */
interface ISY {
    // ERC20
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);

    // ERC4626-like
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
}
