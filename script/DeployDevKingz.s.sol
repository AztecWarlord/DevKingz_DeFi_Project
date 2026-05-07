// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {Script} from "forge-std/Script.sol";
// import {DevKingz} from "../src/devKingz.sol";
//import {DevKingz} from "../test/mocks/MockDevKingzNFT.sol";
// import {HelperConfig} from "../script/HelperConfig.s.sol";
// import {AddConsumer, CreateSubscription, FundSubscription} from "../script/Interactions.s.sol";

// contract DeployDevKingz is Script {
//     function run() public {}

//     function deployDevKingz() public returns (DevKingz, HelperConfig) {
//         HelperConfig helperConfig = new HelperConfig();
//         // local -> deploy mock, get local config
//         // sepolia -> get sepolia config
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//         if (config.subId == 0) {
//             // create subscription
//             CreateSubscription createSubscription = new CreateSubscription();
//             (config.subId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator);

//             // fund subscription
//             FundSubscription fundSubscription = new FundSubscription();
//             fundSubscription.fundSubscription(config.vrfCoordinator, config.subId, config.link);
//         }
//         vm.startBroadcast();
//         DevKingz devKingz = new DevKingz(
//             config.vrfCoordinator,
//             config.subId,
//             config.keyHash,
//             config.callbackGasLimit,
//             config.mintFee,
//             config.devTokenUris
//         );
//         vm.stopBroadcast();

//         AddConsumer addConsumer = new AddConsumer();
//         addConsumer.addConsumer(address(devKingz), config.vrfCoordinator, config.subId);

//         return (devKingz, helperConfig);
//     }
// }
