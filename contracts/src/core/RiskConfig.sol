// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

contract RiskConfig is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // caps expressed in basis points (10000 = 100%)
    uint16 public maxPerAdapterBps;   // e.g., 3000 = 30%
    uint16 public maxPerAssetBps;     // e.g., 4000 = 40%
    uint16 public maxShiftPerRebalanceBps; // e.g., 2000 = 20%

    // emergency settings
    bool public pausedAll;

    event CapsUpdated(uint16 perAdapter, uint16 perAsset, uint16 shiftBps);
    event PausedAll(bool paused);

    constructor(address admin, uint16 _perAdapter, uint16 _perAsset, uint16 _shift) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        maxPerAdapterBps = _perAdapter;
        maxPerAssetBps = _perAsset;
        maxShiftPerRebalanceBps = _shift;
    }

    function setCaps(uint16 perAdapter, uint16 perAsset, uint16 shiftBps) external onlyRole(MANAGER_ROLE) {
        maxPerAdapterBps = perAdapter;
        maxPerAssetBps = perAsset;
        maxShiftPerRebalanceBps = shiftBps;
        emit CapsUpdated(perAdapter, perAsset, shiftBps);
    }

    function setPausedAll(bool p) external onlyRole(MANAGER_ROLE) {
        pausedAll = p;
        emit PausedAll(p);
    }
}
