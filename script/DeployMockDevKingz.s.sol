// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DevKingz} from "../test/mocks/MockDevKingzNFT.sol";

contract DeployMockDevKingz is Script {
    function run() public {}

    function deployMockDevKingz() public returns (DevKingz) {
        vm.startBroadcast();
        DevKingz devKingz = new DevKingz();
        vm.stopBroadcast();
        return devKingz;
    }
}
