// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {DeployDevKingz} from "../../script/DeployDevKingz.s.sol";
// import {DevKingz} from "../../src/devKingz.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {Vm} from "forge-std/Vm.sol";
// import {VRFCoordinatorV2_5Mock} from "@chainlink-brownie/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

// contract DevKingzTest is Test {
//     string constant NFT_NAME = "DevKingz";
//     string constant NFT_SYMBOL = "DKZ";
//     DevKingz public devKingz;
//     HelperConfig public helperConfig;

//     error DevKingz__NotWarlord();

//     /* Types of DevKingz */
//     enum Dev {
//         GOLDDEV,
//         SILVERDEV,
//         LILDEV
//     }

//     address vrfCoordinator;
//     uint256 subId;
//     bytes32 keyHash; // keyHash
//     uint32 callbackGasLimit;
//     uint256 mintFee;
//     string[3] devTokenUris;
//     address private immutable i_owner = msg.sender;

//     address public USER = makeAddr("user");
//     uint256 public constant STARTING_USER_BALANCE = 10 ether;
//     uint256 public constant CONTRACT_BALANCE = 10 ether;
//     uint256 internal constant MAX_CHANCE_VALUE = 500;

//     event NFTRequested(uint256 indexed requestId, address indexed requester);
//     event NFTMinted(uint256 indexed tokenId, Dev indexed devType, address indexed minter);
//     event WithdrawFunds(address indexed owner, uint256 amount);

//     function setUp() external {
//         DeployDevKingz deployer = new DeployDevKingz();
//         (devKingz, helperConfig) = deployer.deployDevKingz();
//         vm.deal(USER, STARTING_USER_BALANCE);

//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
//         vrfCoordinator = config.vrfCoordinator;
//         subId = config.subId;
//         keyHash = config.keyHash;
//         callbackGasLimit = config.callbackGasLimit;
//         mintFee = config.mintFee;
//         devTokenUris = config.devTokenUris;
//     }

//     /*//////////////////////////////////////////////////////////////
//                             CONTRACT INITIALIZATION
//     //////////////////////////////////////////////////////////////*/

//     function test__initializedContract() public view {
//         bool s_initialized = devKingz.getInitializedContract();
//         assert(bool(s_initialized));
//     }

//     function test_InitializedCorrectly() public view {
//         assert(keccak256(abi.encodePacked(devKingz.name())) == keccak256(abi.encodePacked((NFT_NAME))));
//         assert(keccak256(abi.encodePacked(devKingz.symbol())) == keccak256(abi.encodePacked((NFT_SYMBOL))));
//     }

//     function test_userBalance() public view returns (address, uint256) {
//         console.log("USER starting ether balance:", USER.balance);
//         return (address(USER), USER.balance);
//     }

//     /*//////////////////////////////////////////////////////////////
//                             REQUEST NFT
//     //////////////////////////////////////////////////////////////*/

//     modifier nftRequested() {
//         vm.prank(USER);
//         uint256 requestId = devKingz.requestNFT{value: mintFee}();
//         emit NFTRequested(requestId, USER);
//         _;
//     }

//     modifier skipFork() {
//         if (block.chainid != 84532) {
//             return;
//         }
//         _;
//     }

//     function test_checksTheMintFee() public view {
//         // Arrange
//         uint256 expectedMintFee = mintFee;
//         // Act
//         uint256 actualMintFee = devKingz.getMintFee();
//         // Assert
//         assert(actualMintFee == expectedMintFee);
//     }

//     function test_RevertsIfUserBalanceIsBelowMintFee() public {
//         // Arrange
//         vm.prank(USER);
//         // Act/Assert
//         vm.expectRevert(DevKingz.DevKingz__NeedMoreEthSent.selector);
//         devKingz.requestNFT();
//     }

//     function test_requestNFTEmitsEvent() public {
//         // Arrange
//         vm.prank(USER);
//         // Act/Assert
//         uint256 requestId = devKingz.requestNFT{value: mintFee}();
//         emit NFTRequested(requestId, USER);
//     }

//     function test_tokenURIIsCorrect() public nftRequested {
//         // Arrange
//         vm.prank(USER);
//         uint256 tokenId = 0;
//         Dev devType;
//         emit NFTMinted(tokenId, devType, USER);
//         assert(
//             keccak256(abi.encodePacked(devKingz.getDevTokenUris(tokenId)))
//                 == keccak256(abi.encodePacked(devTokenUris[uint256(devType)]))
//         );
//     }

//     function test_mapsRequestIdToSender() public nftRequested {
//         // Arrange
//         uint256 requestId = 1;
//         // Act/Assert
//         assert(devKingz.getRequestIdToSender(requestId) == USER);
//     }

//     /*//////////////////////////////////////////////////////////////
//                             FULFILLRANDOMWORDS
//     //////////////////////////////////////////////////////////////*/

//     function test_fulfillRandomWordsMintNFTAfterRNGReturned() public nftRequested skipFork {
//         // Arrange
//         uint256 randomWords = 1;
//         DevKingz.Dev devTypeEnum = devKingz.getDevFromModdedRng(randomWords);
//         uint256 moddedRng = uint256(devTypeEnum);
//         Dev devType = Dev(uint256(moddedRng));
//         // Act/Assert
//         VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomWords, address(devKingz));
//         emit NFTMinted(0, devType, USER);
//     }

//     function test_checksIfTokenCounterIsIncremented() public nftRequested skipFork {
//         // Arrange
//         uint256 randomWords = 1;
//         DevKingz.Dev devTypeEnum = devKingz.getDevFromModdedRng(randomWords);
//         uint256 moddedRng = uint256(devTypeEnum);
//         Dev devType = Dev(uint256(moddedRng));
//         // Act/Assert
//         VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomWords, address(devKingz));
//         emit NFTMinted(0, devType, USER);
//         assert(devKingz.getTokenCounter() == 1);
//     }

//     function test_getChanceArray() public view {
//         // Arrange
//         assert(devKingz.getChanceArray().length == 3);
//     }

//     function test_devIsReturnedFromModdedRng() public view {
//         // Arrange
//         uint256 moddedRng = 0;
//         // Act/Assert
//         DevKingz.Dev devType = devKingz.getDevFromModdedRng(moddedRng);

//         assert(devKingz.getDevFromModdedRng(moddedRng) == DevKingz.Dev(uint8(devType)));
//     }

//     function test_checkIfNftMintedIsSentToCorrectOwner() public nftRequested skipFork {
//         // Arrange
//         uint256 randomWords = 1;
//         DevKingz.Dev devTypeEnum = devKingz.getDevFromModdedRng(randomWords);
//         uint256 moddedRng = uint256(devTypeEnum);
//         Dev devType = Dev(uint256(moddedRng));
//         // Act/Assert
//         VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomWords, address(devKingz));
//         emit NFTMinted(0, devType, USER);
//         assert(devKingz.ownerOf(0) == USER);
//     }

//     /*//////////////////////////////////////////////////////////////
//                             WITHDRAW FUNDS
//     //////////////////////////////////////////////////////////////*/
//     /**
//      * @dev Throws if called by any account other than the owner.
//      */
//     modifier onlyWarlord() {
//         // require(msg.sender == i_owner);
//         if (msg.sender != i_owner) revert DevKingz__NotWarlord();
//         _;
//     }

//     function test_msgSenderIsWarlord() public view onlyWarlord {
//         // Arrange
//         // Act/Assert
//         assert(msg.sender == i_owner);
//         console.log("OnlyWarlord is:", msg.sender);
//     }

//     function test_checkContractBalance() public {
//         // Arrange
//         vm.deal(address(devKingz), CONTRACT_BALANCE);

//         // Assert
//         assert(devKingz.getContractBalance() == 10 ether);
//     }

//     function test_revertsIfThereAreNoFunds() public {
//         vm.startPrank(i_owner);
//         // Arrange
//         vm.expectRevert(DevKingz.DevKingz__NoFundsToWithdraw.selector);
//         // Act
//         devKingz.withdrawFunds();
//         vm.stopPrank();
//     }

//     function test_revertOnlyWarlordCanWithdrawFunds() public onlyWarlord {
//         // Arrange
//         vm.prank(address(this));
//         // Act/Assert
//         vm.expectRevert(DevKingz.DevKingz__NotWarlord.selector);
//         devKingz.withdrawFunds();
//     }

//     function test_withdrawFundsRevertsWhenTransferFails() public {
//         // Arrange
//         vm.deal(address(devKingz), 0);
//         vm.prank(i_owner);
//         // Act/Assert
//         vm.expectRevert(DevKingz.DevKingz__NoFundsToWithdraw.selector);
//         devKingz.withdrawFunds();
//     }

//     function test_withdrawFundsEmitsEvent() public onlyWarlord {
//         // Arrange
//         vm.deal(address(devKingz), CONTRACT_BALANCE);
//         vm.prank(i_owner);
//         // console.log(i_owner.balance);

//         // Act/Assert
//         emit WithdrawFunds(i_owner, CONTRACT_BALANCE);
//         devKingz.withdrawFunds();
//         console.log(i_owner.balance);
//     }

//     function test_warlordWithdrawsFunds() public onlyWarlord {
//         // Arrange
//         vm.deal(address(devKingz), CONTRACT_BALANCE);
//         vm.prank(i_owner);
//         // Act
//         uint256 preBalance = address(devKingz).balance;
//         console.log("Pre-Balance:", preBalance);
//         devKingz.withdrawFunds();
//         uint256 postBalance = address(devKingz).balance;
//         // Assert
//         assertEq(preBalance - 10 ether, postBalance);
//         console.log("Post-Balance:", postBalance);
//         console.log("Warlord Balance:", address(i_owner).balance);
//     }
// }