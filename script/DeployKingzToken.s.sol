// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {KingzToken} from "../src/kingzToken.sol";

contract DeployKingzToken is Script {
    function run() public {}

    function deployKingzToken() public returns (KingzToken) {
        vm.startBroadcast();
        KingzToken kingzToken = new KingzToken(address(this));
        vm.stopBroadcast();
        return kingzToken;
    }
}
