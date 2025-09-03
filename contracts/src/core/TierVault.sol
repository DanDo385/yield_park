// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IStrategyAdapter} from "../interfaces/IStrategyAdapter.sol";
import {StrategyRegistry} from "./StrategyRegistry.sol";
import {RiskConfig} from "./RiskConfig.sol";

contract TierVault is ERC4626, Pausable, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    StrategyRegistry public immutable registry;
    RiskConfig public immutable risk;

    // Adapter weights (basis points). Sum <= 10000. targetWeights[adapter] -> bps
    mapping(address => uint16) public targetWeights;
    address[] public activeAdapters;

    event TargetWeightsSet(address[] adapters, uint16[] bps);
    event Harvested(address indexed adapter, uint256 gain, uint256 apr);
    event Rebalanced();

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_,
        address admin,
        StrategyRegistry reg_,
        RiskConfig risk_
    ) ERC20(name_, symbol_) ERC4626(asset_) {
        registry = reg_;
        risk = risk_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    // ── Views ──────────────────────────────────────────────────────────────────
    function adapters() external view returns (address[] memory) { return activeAdapters; }

    function totalAssets() public view override returns (uint256) {
        uint256 sum = IERC20(asset()).balanceOf(address(this));
        for (uint256 i = 0; i < activeAdapters.length; i++) {
            sum += IStrategyAdapter(activeAdapters[i]).totalAssets();
        }
        return sum;
    }

    // ── Admin (weights) ────────────────────────────────────────────────────────
    function setTargetWeights(address[] calldata adapters_, uint16[] calldata bps) external onlyRole(MANAGER_ROLE) {
        require(adapters_.length == bps.length && adapters_.length > 0, "len");
        delete activeAdapters;
        uint256 total;
        for (uint256 i = 0; i < adapters_.length; i++) {
            address a = adapters_[i];
            require(registry.isAdapter(a), "not-whitelisted");
            targetWeights[a] = bps[i];
            activeAdapters.push(a);
            total += bps[i];
            require(IStrategyAdapter(a).asset() == asset(), "asset-mismatch");
            require(bps[i] <= risk.maxPerAdapterBps(), "per-adapter-cap");
        }
        require(total <= 10000, "sum>100%");
        emit TargetWeightsSet(adapters_, bps);
    }

    // ── Hooks: after deposit/withdraw keep idle; rebalance distributes to targets
    function harvestAll() public whenNotPaused {
        for (uint256 i = 0; i < activeAdapters.length; i++) {
            IStrategyAdapter(activeAdapters[i]).harvest();
            // best-effort: no event payloads here to save gas; optional adapter events exist
        }
    }

    function rebalance() public whenNotPaused onlyRole(MANAGER_ROLE) {
        uint256 tot = totalAssets();
        uint256 idle = IERC20(asset()).balanceOf(address(this));

        // Target amounts
        for (uint256 i = 0; i < activeAdapters.length; i++) {
            address a = activeAdapters[i];
            uint256 targetAmt = (tot * targetWeights[a]) / 10000;
            uint256 cur = IStrategyAdapter(a).totalAssets();

            if (cur < targetAmt) {
                uint256 need = targetAmt - cur;
                // cap shift
                uint256 maxShift = (tot * risk.maxShiftPerRebalanceBps()) / 10000;
                if (need > maxShift) need = maxShift;
                if (need > idle) need = idle;
                if (need > 0) {
                    IERC20(asset()).approve(a, need);
                    IStrategyAdapter(a).deposit(need);
                    idle -= need;
                }
            } else {
                uint256 excess = cur - targetAmt;
                uint256 maxShift = (tot * risk.maxShiftPerRebalanceBps()) / 10000;
                if (excess > maxShift) excess = maxShift;
                if (excess > 0) {
                    uint256 out = IStrategyAdapter(a).withdraw(excess);
                    // idle increased
                    (out);
                }
            }
        }
        emit Rebalanced();
    }

    // ── Pausing ────────────────────────────────────────────────────────────────
    function pause() external onlyRole(MANAGER_ROLE) { _pause(); }
    function unpause() external onlyRole(MANAGER_ROLE) { _unpause(); }
}
