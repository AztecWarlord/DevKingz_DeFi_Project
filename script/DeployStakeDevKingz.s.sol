// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StakeDevKingz} from "../src/StakeDevKingz.sol";
import {KingzToken} from "../src/kingzToken.sol";

contract DeployStakeDevKingz is Script {
    function run() public {}

    function deployStakeDevKingz(address devKingzAddress) public returns (StakeDevKingz, KingzToken) {
        vm.startBroadcast();
        KingzToken kingzToken = new KingzToken(msg.sender);
        StakeDevKingz stakeDevKingz = new StakeDevKingz(devKingzAddress, address(kingzToken));
        kingzToken.transferOwnership(address(stakeDevKingz));
        vm.stopBroadcast();
        return (stakeDevKingz, kingzToken);
    }
}
