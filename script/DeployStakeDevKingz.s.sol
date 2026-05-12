// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StakeDevKingz} from "../src/StakeDevKingz.sol";
import {KingzToken} from "../src/kingzToken.sol";

contract DeployStakeDevKingz is Script {
    // For real deployments — pass devKingzAddress as env or hardcode
    function run() public {
        address devKingzAddress = address(0); // replace with real address
        vm.startBroadcast();
        (StakeDevKingz stakeDevKingz, KingzToken kingzToken) = _deploy(devKingzAddress);
        vm.stopBroadcast();
    }

    // For tests — called directly, no broadcast
    function deployStakeDevKingz(address devKingzAddress) external returns (StakeDevKingz, KingzToken) {
        return _deploy(devKingzAddress);
    }

    // Shared logic
    function _deploy(address devKingzAddress) internal returns (StakeDevKingz, KingzToken) {
        KingzToken kingzToken = new KingzToken(address(this));
        StakeDevKingz stakeDevKingz = new StakeDevKingz(devKingzAddress, address(kingzToken));
        kingzToken.transferOwnership(address(stakeDevKingz));
        return (stakeDevKingz, kingzToken);
    }
}
