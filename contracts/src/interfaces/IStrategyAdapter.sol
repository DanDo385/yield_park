// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IStrategyAdapter {
    /// @notice The ERC20 asset this adapter accepts/returns (must match vault asset)
    function asset() external view returns (address);

    /// @notice Total assets (in underlying units) managed by the adapter
    function totalAssets() external view returns (uint256);

    /// @notice Best-effort current APR in 1e18 (e.g., 0.05e18 = 5%)
    function currentApr() external view returns (uint256);

    /// @notice Deposit amount of underlying into the strategy; returns shares/pos id (if any)
    function deposit(uint256 assets) external returns (uint256);

    /// @notice Withdraw underlying (assets) from the strategy; returns actual returned assets
    function withdraw(uint256 assets) external returns (uint256);

    /// @notice Harvest/compound rewards to increase underlying position, if applicable
    function harvest() external;

    /// @notice Emitted by adapters for off-chain inventory (optional)
    event Harvest(uint256 gain, uint256 apr);
}
