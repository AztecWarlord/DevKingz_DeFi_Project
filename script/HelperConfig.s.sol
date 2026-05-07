// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {Script} from "forge-std/Script.sol";
// import {VRFCoordinatorV2_5Mock} from "@chainlink-brownie/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {LinkToken} from "../test/mocks/LinkToken.sol";

// abstract contract CodeConstants {
//     /* VRF Mock Values */
//     uint96 public MOCK_BASE_FEE = 0.25 ether;
//     uint96 public MOCK_GAS_PRICE_LINK = 1e9;
//     // LINK / ETH price
//     int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;

//     address public FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

//     // uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
//     uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
//     uint256 public constant LOCAL_CHAIN_ID = 31337;
// }

// contract HelperConfig is Script, CodeConstants {
//     error HelperConfig__ChainIdNotFound();

//     struct NetworkConfig {
//         address vrfCoordinator;
//         uint256 subId;
//         bytes32 keyHash; // keyHash
//         uint32 callbackGasLimit;
//         uint256 mintFee;
//         string[3] devTokenUris;
//         address link;
//     }

//     NetworkConfig public localNetworkConfig;
//     mapping(uint256 chainId => NetworkConfig) public networkConfigs;

//     constructor() {
//         networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getSepoliaBaseConfig();
//     }

//     function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
//         if (networkConfigs[chainId].vrfCoordinator != address(0)) {
//             return networkConfigs[chainId];
//         } else if (chainId == LOCAL_CHAIN_ID) {
//             return getOrCreatAnvilEthConfig();
//         } else {
//             revert HelperConfig__ChainIdNotFound();
//         }
//     }

//     function getConfig() public returns (NetworkConfig memory) {
//         return getConfigByChainId(block.chainid);
//     }

//     function getSepoliaBaseConfig() public pure returns (NetworkConfig memory) {
//         return NetworkConfig({
//             vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
//             subId: 0,
//             keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
//             callbackGasLimit: 500000,
//             mintFee: 0.001 ether,
//             devTokenUris: ["GOLDDEV", "SILVERDEV", "LILDEV"],
//             link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
//         });
//     }

//     function getOrCreatAnvilEthConfig() public returns (NetworkConfig memory) {
//         if (localNetworkConfig.vrfCoordinator != address(0)) {
//             return localNetworkConfig;
//         }
//         //
//         vm.startBroadcast();
//         VRFCoordinatorV2_5Mock vrfCoordinator =
//             new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
//         LinkToken link = new LinkToken();
//         vm.stopBroadcast();

//         localNetworkConfig = NetworkConfig({
//             vrfCoordinator: address(vrfCoordinator),
//             subId: 0,
//             keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // doesn't matter
//             callbackGasLimit: 500000,
//             mintFee: 0.01 ether,
//             devTokenUris: ["GOLDDEV", "SILVERDEV", "LILDEV"],
//             link: address(link)
//         });
//         return localNetworkConfig;
//     }
// }
