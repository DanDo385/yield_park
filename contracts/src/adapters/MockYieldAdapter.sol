// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IStrategyAdapter} from "../interfaces/IStrategyAdapter.sol";

contract MockYieldAdapter is IStrategyAdapter {
    IERC20 public immutable u; // underlying
    uint256 public total;      // underlying units held
    // simple linear APR model; settable by manager for demos
    uint256 public apr1e18;    // e.g., 0.05e18 = 5%
    address public vault;

    modifier onlyVault() {
        require(msg.sender == vault, "only-vault");
        _;
    }

    constructor(IERC20 asset_, address vault_) {
        u = asset_;
        vault = vault_;
    }

    function asset() external view returns (address) { return address(u); }

    function totalAssets() public view returns (uint256) {
        // pretend APR accrues each block (very simplified; not for production)
        return total;
    }

    function currentApr() external view returns (uint256) { return apr1e18; }

    function setApr(uint256 a) external {
        // in demo we allow free change; in prod guard with roles
        apr1e18 = a;
    }

    function deposit(uint256 assets) external onlyVault returns (uint256) {
        require(u.transferFrom(msg.sender, address(this), assets), "transfer-in");
        total += assets;
        return assets;
    }

    function withdraw(uint256 assets) external onlyVault returns (uint256) {
        uint256 amt = assets <= total ? assets : total;
        total -= amt;
        require(u.transfer(msg.sender, amt), "transfer-out");
        return amt;
    }

    function harvest() external onlyVault {
        // mint yield out of thin air to simulate APR:  apr/yr / blocks ~ naive
        // For demo, add 1 bps of position per call
        uint256 gain = total / 10000;
        if (gain > 0) {
            // emulate reward by creating underlying via a mock token that can mint (we'll use MockERC20)
            // If underlying can't mint, this becomes noop; in demo our mock can mint.
            try MockMintable(address(u)).mint(address(this), gain) {} catch {}
            total += gain;
            emit Harvest(gain, apr1e18);
        }
    }
}

interface MockMintable {
    function mint(address to, uint256 amt) external;
}
