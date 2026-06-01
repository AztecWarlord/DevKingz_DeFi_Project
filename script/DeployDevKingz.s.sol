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
import {DevKingz} from "../src/devKingz.sol";
import {HelperConfig, CodeConstants} from "../script/HelperConfig.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "../script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "../test/mocks/VRFCoordinatorV2_5Mock_V2.sol";

/**
 * @title A deployment script for DevKingz_DeFi_Project
 * @author Michael Vargas
 * @notice This script is for deploying the DevKingz contract and setting up the Chainlink VRF subscription
 * @dev Implements Chainlink VRFv2_5
 */

contract DeployDevKingz is Script, CodeConstants {
    function run() public {
        deployDevKingz();
    }

    uint256 public constant SUB_FUND_AMOUNT = 10000 ether; // 100 LINK

    function deployDevKingz() public returns (DevKingz, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mock, get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (block.chainid != LOCAL_CHAIN_ID && config.subId == 0) {
            revert HelperConfig.HelperConfig__UpdateSubscriptionId();
        }
        if (config.subId == 0) {
            // create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subId, config.vrfCoordinatorV2_5) = createSubscription.createSubscription(config.vrfCoordinatorV2_5);

            // fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinatorV2_5, config.subId, config.link);
        }
        vm.startBroadcast();
        DevKingz devKingz = new DevKingz(
            config.vrfCoordinatorV2_5,
            config.subId,
            config.keyHash,
            config.callbackGasLimit,
            config.mintFee,
            config.devTokenUris
        );

        VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5).addConsumer(config.subId, address(devKingz));
        vm.stopBroadcast();

        return (devKingz, helperConfig);
    }
}
