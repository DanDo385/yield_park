// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {TierVault} from "./TierVault.sol";
import {StrategyRegistry} from "./StrategyRegistry.sol";
import {RiskConfig} from "./RiskConfig.sol";

contract BronzeVault is TierVault {
    constructor(
        ERC20 asset_,
        address admin,
        StrategyRegistry reg_,
        RiskConfig risk_
    ) TierVault(asset_, "Bronze Yield Vault", "BRONZE", admin, reg_, risk_) {}
}
