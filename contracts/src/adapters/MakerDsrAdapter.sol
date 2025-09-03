// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { IStrategyAdapter } from "../interfaces/IStrategyAdapter.sol";

/**
 * @title MakerDsrAdapter (sDAI)
 * @notice Deposits DAI into sDAI (ERC-4626) and holds sDAI shares here.
 *         totalAssets() = sDAI.convertToAssets(sDAI.balanceOf(this))
 *
 * Constructor args:
 *  - dai_   : DAI token (underlying for the vault)
 *  - sDai_  : Savings DAI (ERC-4626) token address
 *  - vault_ : TierVault address (only-vault)
 */
contract MakerDsrAdapter is IStrategyAdapter {
    using SafeERC20 for IERC20;

    IERC20 public immutable dai;
    ISavingsDai public immutable sDai;
    address public immutable vault;

    modifier onlyVault() {
        require(msg.sender == vault, "MakerDsrAdapter: only vault");
        _;
    }

    constructor(IERC20 dai_, address sDai_, address vault_) {
        dai = dai_;
        sDai = ISavingsDai(sDai_);
        vault = vault_;
    }

    // ===== IStrategyAdapter =====
    function asset() external view returns (address) { return address(dai); }

    function totalAssets() public view returns (uint256) {
        uint256 shares = sDai.balanceOf(address(this));
        return sDai.convertToAssets(shares);
    }

    function currentApr() external view returns (uint256) {
        // sDAI accrues in share price; no easy APR view here cross-chain.
        // You can compute implied APR off-chain from share price delta, or query Maker/Spark feeds.
        return 0;
    }

    function deposit(uint256 assets) external onlyVault returns (uint256) {
        dai.safeTransferFrom(msg.sender, address(this), assets);
        dai.approve(address(sDai), 0);
        dai.approve(address(sDai), assets);
        uint256 shares = sDai.deposit(assets, address(this));
        return shares;
    }

    function withdraw(uint256 assets) external onlyVault returns (uint256) {
        // redeem shares corresponding to `assets` (rounding up to be safe)
        uint256 shares = sDai.convertToShares(assets);
        if (sDai.convertToAssets(shares) < assets) {
            // round up 1 share if needed due to rounding
            shares += 1;
        }
        uint256 out = sDai.redeem(shares, address(this), address(this));
        dai.safeTransfer(msg.sender, out);
        return out;
    }

    function harvest() external onlyVault {
        emit Harvest(0, 0); // yield auto-accrues in sDAI share price
    }
}

/* -------------------- Minimal sDAI (ERC-4626) interface -------------------- */
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
