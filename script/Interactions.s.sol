// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {Script, console} from "forge-std/Script.sol";
// import {HelperConfig} from "../script/HelperConfig.s.sol";
// import {DevKingz} from "../src/devKingz.sol";
//import {DevKingz} from "../test/mocks/MockDevKingzNFT.sol";
// import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
// import {VRFCoordinatorV2_5Mock} from "@chainlink-brownie/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {CodeConstants} from "../script/HelperConfig.s.sol";
// import {LinkToken} from "../test/mocks/LinkToken.sol";

// contract CreateSubscription is Script {
//     function createSubscriptionUsingConfig() public returns (uint256, address) {
//         HelperConfig helperConfig = new HelperConfig();
//         address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
//         (uint256 subId,) = createSubscription(vrfCoordinator);
//         return (subId, vrfCoordinator);
//     }

//     function createSubscription(address vrfCoordinator) public returns (uint256, address) {
//         console.log("Creating Subscription  on chain Id: ", block.chainid);
//         vm.startBroadcast();
//         uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
//         vm.stopBroadcast();
//         console.log("Your subscription Id is: ", subId);
//         console.log("Please update the subscription Id in your HelperConfig.s.sol");
//         return (subId, vrfCoordinator);
//     }

//     function run() public {
//         createSubscriptionUsingConfig();
//     }
// }

// contract FundSubscription is Script, CodeConstants {
//     uint256 public constant FUND_AMOUNT = 100 ether; // 100 LINK

//     function fundSubscriptionUsingConfig() public {
//         HelperConfig helperConfig = new HelperConfig();
//         address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
//         uint256 subId = helperConfig.getConfig().subId;
//         address link = helperConfig.getConfig().link;
//         fundSubscription(vrfCoordinator, subId, link);
//     }

//     function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken) public {
//         console.log("Funding subscription: ", subId);
//         console.log("Using vrfCoordinator: ", vrfCoordinator);
//         console.log("On Chain Id: ", block.chainid); // 84532

//         if (block.chainid == LOCAL_CHAIN_ID) {
//             vm.startBroadcast();
//             VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
//             vm.stopBroadcast();
//         } else {
//             vm.startBroadcast();
//             LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
//             vm.stopBroadcast();
//         }
//     }

//     function run() public {
//         fundSubscriptionUsingConfig();
//     }
// }

// contract AddConsumer is Script {
//     function addConsumerUsingConfig(address mostRecentlyDeployed) public {
//         HelperConfig helperConfig = new HelperConfig();
//         uint256 subId = helperConfig.getConfig().subId;
//         address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
//         addConsumer(mostRecentlyDeployed, vrfCoordinator, subId);
//     }

//     function addConsumer(address contractToAddtoVRF, address vrfCoordinator, uint256 subId) public {
//         console.log("Adding Consumer to VRF Coordinator: ", contractToAddtoVRF);
//         console.log("To vrfCoordinator: ", vrfCoordinator);
//         console.log("On Chain Id: ", block.chainid); // 31337
//         vm.startBroadcast();
//         VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddtoVRF);
//         vm.stopBroadcast();
//     }

//     function run() external {
//         // Add Consumer
//         address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("DevKingz", block.chainid);
//         addConsumerUsingConfig(mostRecentlyDeployed);
//     }
// }
