// SPDX-License-Identifier: MIT

//  /$$$$$$$                       /$$   /$$ /$$
// | $$__  $$                     | $$  /$$/|__/
// | $$  \ $$  /$$$$$$  /$$    /$$| $$ /$$/  /$$ /$$$$$$$   /$$$$$$  /$$$$$$$$
// | $$  | $$ /$$__  $$|  $$  /$$/| $$$$$/  | $$| $$__  $$ /$$__  $$|____ /$$/
// | $$  | $$| $$$$$$$$ \  $$/$$/ | $$  $$  | $$| $$  \ $$| $$  \ $$   /$$$$/
// | $$  | $$| $$_____/  \  $$$/  | $$\  $$ | $$| $$  | $$| $$  | $$  /$$__/
// | $$$$$$$/|  $$$$$$$   \  $/   | $$ \  $$| $$| $$  | $$|  $$$$$$$ /$$$$$$$$
// |_______/  \_______/    \_/    |__/  \__/|__/|__/  |__/ \____  $$|________/
//                                                         /$$  \ $$
//                                                        |  $$$$$$/
//                                                         \______/
//   _
//  | |__ _  _
//  | '_ \ || |
//  |_.__/\_, |
//        |__/
//    _____            __                __      __              .__                   .___
//   /  _  \ _________/  |_  ____   ____/  \    /  \_____ _______|  |   ___________  __| _/
//  /  /_\  \\___   /\   __\/ __ \_/ ___\   \/\/   /\__  \\_  __ \  |  /  _ \_  __ \/ __ |
// /    |    \/    /  |  | \  ___/\  \___\        /  / __ \|  | \/  |_(  <_> )  | \/ /_/ |
// \____|__  /_____ \ |__|  \___  >\___  >\__/\  /  (____  /__|  |____/\____/|__|  \____ |
//         \/      \/           \/     \/      \/        \/                             \/

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StakeDevKingz} from "../src/StakeDevKingz.sol";
import {KingzToken} from "../src/kingzToken.sol";

/**
 * @title A NFT staking deployment smart contract of DevKingz_DeFi_Project
 * @author Michael Vargas
 * @notice This contract is for staking NFTs
 * @dev Implements Chainlink VRFv2_5
 */

contract DeployStakeDevKingz is Script {
    error DeployStakeDevKingz__DevKingzAddressRequired();

    function run() public {
        address devKingzAddress = vm.envOr("DEVKINGZ_ADDRESS", address(0));

        if (block.chainid != 31337 && devKingzAddress == address(0)) {
            revert DeployStakeDevKingz__DevKingzAddressRequired();
        }

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
        stakeDevKingz.grantRole(stakeDevKingz.DEFAULT_ADMIN_ROLE(), msg.sender);
        return (stakeDevKingz, kingzToken);
    }
}
