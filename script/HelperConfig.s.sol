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
import {LinkToken} from "../test/mocks/LinkToken.sol";
/*
 * @dev This import is used to avoid overflow from the VRFCoordinatorV2_5Mock when testing locally.
*/
import {VRFCoordinatorV2_5Mock} from "../test/mocks/VRFCoordinatorV2_5Mock_V2.sol";

abstract contract CodeConstants {
    /* VRF Mock Values */
    uint96 public mockBaseFee = 0.25 ether;
    uint96 public mockGasPriceLink = 1e9;
    // LINK / ETH price
    int256 public mockWeiPerUnitLink = 4e15;

    address public foundryDefaultSender = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__ChainIdNotFound();
    error HelperConfig__UpdateSubscriptionId();

    struct NetworkConfig {
        address vrfCoordinatorV2_5;
        uint256 subId;
        bytes32 keyHash; // keyHash
        uint32 callbackGasLimit;
        uint256 mintFee;
        string[3] devTokenUris;
        address link;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getSepoliaBaseConfig();
    }

    function getConfigByChainId(uint256 chainid) public returns (NetworkConfig memory) {
        if (networkConfigs[chainid].vrfCoordinatorV2_5 != address(0)) {
            return networkConfigs[chainid];
        } else if (chainid == LOCAL_CHAIN_ID) {
            return getOrCreatAnvilEthConfig();
        } else {
            revert HelperConfig__ChainIdNotFound();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaBaseConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subId: 0,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            mintFee: 0.001 ether,
            devTokenUris: [
                "ipfs://bafybeiconkqwrhofxdfxmergoqcdtbxs5khgc4a3yvo62m5s6geei2tlay",
                "ipfs://bafybeia6m55goimrd63djpl6bepqpe6wemg4hltwsbbkxdxmehngfxi3f4",
                "ipfs://bafybeidiivcgndtvpc4lrl7kme7rx5ycxvxgrk4tgzzbrmlzh3nfkp23k4"
            ],
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getOrCreatAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinatorV2_5 != address(0)) {
            return localNetworkConfig;
        }
        //
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator =
            new VRFCoordinatorV2_5Mock(mockBaseFee, mockGasPriceLink, mockWeiPerUnitLink);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            vrfCoordinatorV2_5: address(vrfCoordinator),
            subId: 0,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // doesn't matter
            callbackGasLimit: 5000000,
            mintFee: 0.01 ether,
            devTokenUris: [
                "ipfs://bafybeiconkqwrhofxdfxmergoqcdtbxs5khgc4a3yvo62m5s6geei2tlay",
                "ipfs://bafybeia6m55goimrd63djpl6bepqpe6wemg4hltwsbbkxdxmehngfxi3f4",
                "ipfs://bafybeidiivcgndtvpc4lrl7kme7rx5ycxvxgrk4tgzzbrmlzh3nfkp23k4"
            ],
            link: address(link)
        });
        return localNetworkConfig;
    }
}
