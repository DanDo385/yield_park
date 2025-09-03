// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

interface IRebalanceable {
    function harvestAll() external;
    function rebalance() external;
}

contract RebalanceUpkeep is AccessControl {
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    IRebalanceable public immutable vault;

    constructor(address admin, IRebalanceable v) {
        vault = v;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KEEPER_ROLE, admin);
    }

    function performUpkeep(bytes calldata) external onlyRole(KEEPER_ROLE) {
        vault.harvestAll();
        vault.rebalance();
    }
}
