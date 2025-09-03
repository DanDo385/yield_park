// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

contract StrategyRegistry is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(address => bool) public isAdapter;
    address[] public adapters;

    event AdapterAdded(address indexed adapter);
    event AdapterRemoved(address indexed adapter);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    function addAdapter(address adapter) external onlyRole(MANAGER_ROLE) {
        require(!isAdapter[adapter], "exists");
        isAdapter[adapter] = true;
        adapters.push(adapter);
        emit AdapterAdded(adapter);
    }

    function removeAdapter(address adapter) external onlyRole(MANAGER_ROLE) {
        require(isAdapter[adapter], "not-found");
        isAdapter[adapter] = false;
        emit AdapterRemoved(adapter);
    }

    function listAdapters() external view returns (address[] memory) {
        return adapters;
    }
}
