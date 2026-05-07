// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StakeDevKingz} from "../src/StakeDevKingz.sol";
import {KingzToken} from "../src/kingzToken.sol";

contract DeployStakeDevKingz is Script {
    function run() public {}

    function deployStakeDevKingz(address devKingzAddress, address kingzTokenAddress) public returns (StakeDevKingz, KingzToken) {
        KingzToken kingzToken = new KingzToken(address(this));
        vm.startBroadcast();
        StakeDevKingz stakeDevKingz = new StakeDevKingz(devKingzAddress, kingzTokenAddress);
        vm.stopBroadcast();
        return (stakeDevKingz, kingzToken);
    }
}