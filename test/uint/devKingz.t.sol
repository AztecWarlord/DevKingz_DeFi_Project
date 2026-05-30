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

import {Test, console} from "forge-std/Test.sol";
import {DeployDevKingz} from "../../script/DeployDevKingz.s.sol";
import {DevKingz} from "../../src/devKingz.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink-brownie/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DevKingzTest is Test {
    string constant NFT_NAME = "DevKingz";
    string constant NFT_SYMBOL = "DKZ";
    DevKingz public devKingz;
    HelperConfig public helperConfig;
    CodeConstants public codeConstants;
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;

    error DevKingz__NotWarlord();

    /* Types of DevKingz */
    enum Dev {
        GOLDDEV,
        SILVERDEV,
        LILDEV
    }

    address vrfCoordinator;
    uint256 subId;
    bytes32 keyHash; // keyHash
    uint32 callbackGasLimit;
    uint256 mintFee;
    string[3] devTokenUris;
    address private immutable I_OWNER = msg.sender;

    address public user = makeAddr("user");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant CONTRACT_BALANCE = 10 ether;
    uint256 internal constant MAX_CHANCE_VALUE = 500;

    event NFTRequested(uint256 indexed requestId, address indexed requester);
    event NFTMinted(uint256 indexed tokenId, Dev indexed devType, address indexed minter);
    event WithdrawFunds(address indexed owner, uint256 amount);

    function setUp() external {
        DeployDevKingz deployer = new DeployDevKingz();
        (devKingz, helperConfig) = deployer.deployDevKingz();
        vm.deal(user, STARTING_USER_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinator = config.vrfCoordinatorV2_5;
        subId = config.subId;
        keyHash = config.keyHash;
        callbackGasLimit = config.callbackGasLimit;
        mintFee = config.mintFee;
        devTokenUris = config.devTokenUris;
    }

    /*//////////////////////////////////////////////////////////////
                            CONTRACT INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function test_initializedContract() public view {
        for (uint256 i = 0; i < devTokenUris.length; i++) {
            assert(
                keccak256(abi.encodePacked(devKingz.getDevTokenUris(i))) == keccak256(abi.encodePacked(devTokenUris[i]))
            );
        }
    }

    function test_userBalance() public view returns (address, uint256) {
        console.log("USER starting ether balance:", user.balance);
        return (address(user), user.balance);
    }

    /*//////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyWarlord() {
        _onlyWarlord();
        _;
    }

    function _onlyWarlord() internal view {
        if (msg.sender != I_OWNER) revert DevKingz__NotWarlord();
    }

    /**
     * @dev Modifier to request an NFT and emit the NFTRequested event. This is used to test the requestNft function and the fulfillRandomWords function together. It ensures that the requestNft function is called before the fulfillRandomWords function, and that the correct events are emitted.
     *      Calls a request for randomness from Chainlink VRF.
     */
    modifier nftRequested() {
        vm.prank(user);
        uint256 requestId = devKingz.requestNft{value: mintFee}();
        emit NFTRequested(requestId, user);
        _;
    }

    modifier onlyOnFork() {
        if (block.chainid == BASE_SEPOLIA_CHAIN_ID) {
            _;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            REQUEST NFT
    //////////////////////////////////////////////////////////////*/

    function test_checksTheMintFee() public view {
        // Arrange
        uint256 expectedMintFee = mintFee;
        // Act
        uint256 actualMintFee = devKingz.getMintFee();
        // Assert
        assert(actualMintFee == expectedMintFee);
    }

    function test_RevertsIfUserBalanceIsBelowMintFee() public {
        // Arrange
        vm.prank(user);
        // Act/Assert
        vm.expectRevert(DevKingz.DevKingz__NeedMoreEthSent.selector);
        devKingz.requestNft();
    }

    function test_requestNftEmitsEvent() public {
        // Arrange
        vm.prank(user);
        // Act/Assert
        uint256 requestId = devKingz.requestNft{value: mintFee}();
        emit NFTRequested(requestId, user);
    }

    function test_tokenURIIsCorrect() public nftRequested {
        // Arrange
        vm.prank(user);
        uint256 tokenId = 0;
        Dev devType;
        emit NFTMinted(tokenId, devType, user);
        assert(
            keccak256(abi.encodePacked(devKingz.getDevTokenUris(tokenId)))
                == keccak256(abi.encodePacked(devTokenUris[uint256(devType)]))
        );
    }

    function test_mapsRequestIdToSender() public nftRequested {
        // Arrange
        uint256 requestId = 1;
        // Act/Assert
        assert(devKingz.getRequestIdToSender(requestId) == user);
    }

    /*//////////////////////////////////////////////////////////////
                            FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    function test_fulfillRandomWordsMintNFTAfterRNGReturned() public nftRequested onlyOnFork {
        // Arrange
        uint256 randomWords = 1;
        DevKingz.Dev devTypeEnum = devKingz.getDevFromModdedRng(randomWords);
        uint256 moddedRng = uint256(devTypeEnum);
        Dev devType = Dev(uint256(moddedRng));
        // Act/Assert
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomWords, address(devKingz));
        emit NFTMinted(0, devType, user);
    }

    function test_checksIfTokenCounterIsIncremented() public nftRequested onlyOnFork {
        // Arrange
        uint256 randomWords = 1;
        DevKingz.Dev devTypeEnum = devKingz.getDevFromModdedRng(randomWords);
        uint256 moddedRng = uint256(devTypeEnum);
        Dev devType = Dev(uint256(moddedRng));
        // Act/Assert
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomWords, address(devKingz));
        emit NFTMinted(0, devType, user);
        assert(devKingz.getTokenCounter() == 1);
    }

    function test_getChanceArray() public view {
        // Arrange
        assert(devKingz.getChanceArray().length == 3);
    }

    function test_devIsReturnedFromModdedRng() public view {
        // Arrange
        uint256 moddedRng = 1;
        // Act/Assert
        DevKingz.Dev devType = devKingz.getDevFromModdedRng(moddedRng);

        assert(devKingz.getDevFromModdedRng(moddedRng) == DevKingz.Dev(uint8(devType)));
    }

    function test_checkIfNftMintedIsSentToCorrectOwner() public nftRequested onlyOnFork {
        // Arrange
        uint256 randomWords = 1;
        DevKingz.Dev devTypeEnum = devKingz.getDevFromModdedRng(randomWords);
        uint256 moddedRng = uint256(devTypeEnum);
        Dev devType = Dev(uint256(moddedRng));
        // Act/Assert
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomWords, address(devKingz));
        emit NFTMinted(0, devType, user);
        assert(devKingz.ownerOf(0) == user);
    }

    function test_requestIdToSenderIsMsgSender() public nftRequested {
        // Arrange
        uint256 requestId = 1;
        // Act/Assert
        assert(devKingz.getRequestIdToSender(requestId) == user);
        console.log("Request ID to Sender:", devKingz.getRequestIdToSender(requestId));
    }

    function test_fullfillRandomWords() public nftRequested onlyOnFork {
        // Arrange
        uint256 randomWords = 1;
        DevKingz.Dev devTypeEnum = devKingz.getDevFromModdedRng(randomWords);
        uint256 moddedRng = uint256(devTypeEnum);
        Dev devType = Dev(uint256(moddedRng));
        // Act/Assert
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomWords, address(devKingz));
        emit NFTMinted(0, devType, user);
        assert(devKingz.getTokenCounter() == 1);
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAW FUNDS
    //////////////////////////////////////////////////////////////*/

    function test_msgSenderIsWarlord() public view onlyWarlord {
        // Arrange
        // Act/Assert
        assert(msg.sender == I_OWNER);
        console.log("OnlyWarlord is:", msg.sender);
    }

    function test_checkContractBalance() public {
        // Arrange
        vm.deal(address(devKingz), CONTRACT_BALANCE);

        // Assert
        assert(devKingz.getContractBalance() == 10 ether);
    }

    function test_revertsIfThereAreNoFunds() public {
        vm.startPrank(I_OWNER);
        // Arrange
        vm.expectRevert(DevKingz.DevKingz__NoFundsToWithdraw.selector);
        // Act
        devKingz.withdrawFunds();
        vm.stopPrank();
    }

    function test_revertOnlyWarlordCanWithdrawFunds() public onlyWarlord {
        // Arrange
        vm.prank(address(this));
        // Act/Assert
        vm.expectRevert(DevKingz.DevKingz__NotWarlord.selector);
        devKingz.withdrawFunds();
    }

    function test_withdrawFundsRevertsWhenTransferFails() public {
        // Arrange
        vm.deal(address(devKingz), 0);
        vm.prank(I_OWNER);
        // Act/Assert
        vm.expectRevert(DevKingz.DevKingz__NoFundsToWithdraw.selector);
        devKingz.withdrawFunds();
    }

    function test_withdrawFundsEmitsEvent() public onlyWarlord {
        // Arrange
        vm.deal(address(devKingz), CONTRACT_BALANCE);
        vm.prank(I_OWNER);

        // Act/Assert
        emit WithdrawFunds(I_OWNER, CONTRACT_BALANCE);
        devKingz.withdrawFunds();
        console.log(I_OWNER.balance);
    }

    function test_warlordWithdrawsFunds() public onlyWarlord {
        // Arrange
        vm.deal(address(devKingz), CONTRACT_BALANCE);
        vm.prank(I_OWNER);
        // Act
        uint256 preBalance = address(devKingz).balance;
        console.log("Pre-Balance:", preBalance);
        devKingz.withdrawFunds();
        uint256 postBalance = address(devKingz).balance;
        // Assert
        assertEq(preBalance - 10 ether, postBalance);
        console.log("Post-Balance:", postBalance);
        console.log("Warlord Balance:", address(I_OWNER).balance);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_getTokenCounter() public view {
        // Arrange
        uint256 tokenCounter = devKingz.getTokenCounter();
        // Act/Assert
        assert(tokenCounter == 0);
    }

    function test_getContractBalance() public {
        // Arrange
        vm.deal(address(devKingz), CONTRACT_BALANCE);
        vm.prank(address(devKingz));
        uint256 contractBalance = devKingz.getContractBalance();
        // Act/Assert
        assert(contractBalance == 10 ether);
        console.log("Contract Balance:", contractBalance);
    }
}
