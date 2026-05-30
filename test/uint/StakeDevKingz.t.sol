// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {DevKingz} from "../mocks/MockDevKingzNFT.sol";
// import {DeployMockDevKingz} from "../../script/DeployMockDevKingz.s.sol";
import {StakeDevKingz} from "../../src/StakeDevKingz.sol";
import {DeployStakeDevKingz} from "../../script/DeployStakeDevKingz.s.sol";
import {KingzToken} from "../../src/kingzToken.sol";
import {DevKingz} from "../../src/devKingz.sol";
import {DeployDevKingz} from "../../script/DeployDevKingz.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink-brownie/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

// This contract will test the functionality of the StakeDevKingz smart contract.
contract StakeDevKingzTest is Test {
    StakeDevKingz public stakeDevKingz;
    DevKingz public devKingz;
    KingzToken public kingzToken;
    DeployDevKingz public devKingzDeployer;
    HelperConfig public helperConfig;
    VRFCoordinatorV2_5Mock public vrfCoordinator;

    address public initialOwner = makeAddr("owner");

    struct StakerInfo {
        address owner;
        uint256[] tokenIds;
        uint256 rewards;
    }

    address public USER = makeAddr("user");
    address public SCAMMER = makeAddr("scammer");
    address public ADMIN = makeAddr("admin");
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant STARTING_USER_BALANCE = 100 ether;
    uint256 public constant CONTRACT_BALANCE = 100 ether;
    uint256 public constant SUB_FUND_AMOUNT = 1000 ether; // 100 LINK
    uint256 internal constant REWARD_RATE_PER_SECOND = 1e18; // 1
    address public devKingzAddress;
    uint256 public mintFee;
    string public tokenUri = "ipfs://exampleTokenUri";

    mapping(uint256 => StakerInfo) private vault; // tokenId => Staker

    event NFTStaked(address indexed owner, uint256 indexed tokenIds, uint256 timestamp);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenIds, uint256 timestamp);
    event RewardsClaimed(address indexed owner, uint256 amount);

    function setUp() external {
        DeployDevKingz deployer = new DeployDevKingz();
        (devKingz, helperConfig) = deployer.deployDevKingz();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        mintFee = config.mintFee;
        vrfCoordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV2_5); // ✅ grab coordinator
        uint256 subId = devKingz.getSubId();
        vrfCoordinator.fundSubscription(subId, SUB_FUND_AMOUNT); // ✅ fund it with 1000 LINK
        vm.deal(USER, STARTING_USER_BALANCE);
        DeployStakeDevKingz stakeDeployer = new DeployStakeDevKingz();
        (stakeDevKingz, kingzToken) = stakeDeployer.deployStakeDevKingz(address(devKingz));
        console.log("StakeDevKingz deployed at:", address(stakeDevKingz));
        console.log("KingzToken owner", kingzToken.owner());
        assertEq(kingzToken.owner(), address(stakeDevKingz));
    }

    // Mints a DevKingz NFT to the USER
    modifier mintDevKingzNFT() {
        vm.startPrank(USER);
        vm.deal(USER, STARTING_USER_BALANCE);
        uint256 requestId = devKingz.requestNft{value: mintFee}();
        vm.stopPrank();
        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(requestId, address(devKingz));
        _;
    }

    // Tests that the staking contract is the owner of the KingzToken contract
    function testStakingContractIsOwnerOfKingzToken() external view {
        assertEq(kingzToken.owner(), address(stakeDevKingz));
        console.log("StakeDevKingz is the owner of KingzToken as expected.");
    }

    function testConstructorSetsInitialValues() external view {
        assertEq(address(stakeDevKingz.devKingz()), address(devKingz));
        assertEq(address(stakeDevKingz.kingzToken()), address(kingzToken));
        console.log("Constructor sets correct DevKingz and KingzToken addresses.");
    }

    function testConstructorSetsAdmin() external view {
        assertEq(stakeDevKingz.hasRole(stakeDevKingz.DEFAULT_ADMIN_ROLE(), address(this)), true);
        console.log("Constructor sets correct admin address.");
    }

    // Tests staking functionality
    function testStakeNFT() external mintDevKingzNFT {
        vm.startPrank(USER);

        // Approve the staking contract to transfer the user's NFTs
        devKingz.setApprovalForAll(address(stakeDevKingz), true);

        // Stake the minted NFT (tokenId 0)
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0; // Explicitly set tokenId
        uint256 initialCount = stakeDevKingz.totalStakedDevKingz();
        stakeDevKingz.stakeNFTs(tokenIds);

        // Verify NFT transferred to staking contract
        assertEq(devKingz.balanceOf(address(stakeDevKingz)), 1);
        assertEq(devKingz.balanceOf(USER), 0);

        // Verify vault updated
        (address owner) = stakeDevKingz.vault(0);
        assertEq(owner, USER);
        assertEq(stakeDevKingz.totalStakedDevKingz(), initialCount + 1);
        console.log("Total staked DevKingz increased correctly.", stakeDevKingz.totalStakedDevKingz());
        vm.stopPrank();
    }

    function testChecksIfUserIsDevKingzHolder() external mintDevKingzNFT {
        vm.prank(USER);

        // Check if USER is a DevKingz holder
        devKingz.balanceOf(USER);
        console.log("User's DevKingz NFT balance:", devKingz.balanceOf(USER));

        // Verify that the user holds at least one DevKingz NFT
        assert(devKingz.balanceOf(USER) > 0);
        console.log("User is a DevKingz holder.");
    }

    function testRevertsWhenStakingEmptyArray() external {
        vm.startPrank(USER);
        uint256[] memory emptyArray = new uint256[](0);

        vm.expectRevert(abi.encodeWithSelector(StakeDevKingz.StakeDevKingz__EmptyTokenArray.selector));
        stakeDevKingz.stakeNFTs(emptyArray);
        vm.stopPrank();
    }

    function testRevertsWhenStakingAlreadyStakedToken() external mintDevKingzNFT stakeDevKingzNFTMod {
        vm.startPrank(USER);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        // Second stake should revert
        vm.expectRevert(abi.encodeWithSelector(StakeDevKingz.StakeDevKingz__TokenAlreadyStaked.selector, tokenIds[0]));
        stakeDevKingz.stakeNFTs(tokenIds);
        console.log("Staking already staked token reverted as expected.");
        vm.stopPrank();
    }

    function testStakingEmitsCorrectEvents() external mintDevKingzNFT {
        vm.startPrank(USER);
        devKingz.setApprovalForAll(address(stakeDevKingz), true);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        // Expect event emission
        vm.expectEmit(true, true, false, true);
        emit NFTStaked(USER, 0, block.timestamp);
        stakeDevKingz.stakeNFTs(tokenIds);
        console.log("Staked NFT event emitted correctly.");
        vm.stopPrank();
    }

    function testRevertsWhenStakingWithoutApproval() external mintDevKingzNFT {
        vm.startPrank(USER);
        // Don't approve staking contract

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        // Should revert when transferFrom is called without approval
        vm.expectRevert();
        stakeDevKingz.stakeNFTs(tokenIds);
        console.log("Staking without approval reverted as expected.");
        vm.stopPrank();
    }

    function testStakingMultipleNFTsUpdatesAllVaultEntries() external mintDevKingzNFT {
        vm.startPrank(USER);

        // Mint additional NFTs
        uint256 req_id1 = devKingz.requestNft{value: mintFee}();
        uint256 req_id2 = devKingz.requestNft{value: mintFee}();
        vm.stopPrank(); // Stop pranking to allow VRF fulfillment

        vrfCoordinator.fulfillRandomWords(req_id1, address(devKingz)); // Fulfill for tokenId 1
        vrfCoordinator.fulfillRandomWords(req_id2, address(devKingz)); // Fulfill for tokenId 2

        vm.startPrank(USER);
        devKingz.setApprovalForAll(address(stakeDevKingz), true);

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        stakeDevKingz.stakeNFTs(tokenIds);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            (address owner) = stakeDevKingz.vault(tokenIds[i]);
            assertEq(owner, USER);
        }

        assertEq(stakeDevKingz.totalStakedDevKingz(), 3);
        console.log("Staked count is:", stakeDevKingz.totalStakedDevKingz());
        vm.stopPrank();
    }

    function testNFTStakedByNonOwner() external mintDevKingzNFT {
        // USER owns tokenId 0, SCAMMER tries to stake it without permission
        vm.startPrank(SCAMMER);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0; // USER's NFT

        // Expect revert when SCAMMER tries to stake USER's NFT
        vm.expectRevert();
        stakeDevKingz.stakeNFTs(tokenIds);

        vm.stopPrank();
    }

    // UnstakeNFT uint tests

    modifier stakeDevKingzNFTMod() {
        vm.startPrank(USER);
        devKingz.setApprovalForAll(address(stakeDevKingz), true);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        stakeDevKingz.stakeNFTs(tokenIds);
        vm.stopPrank();
        _;
    }

    function testUnstakeNFT() external mintDevKingzNFT stakeDevKingzNFTMod {
        vm.startPrank(USER);
        uint256 tokenId = 0; // Token minted and staked by modifiers
        uint256 initialCount = stakeDevKingz.totalStakedDevKingz();

        // Expect events
        vm.expectEmit(true, true, false, true);
        emit NFTUnstaked(USER, tokenId, block.timestamp);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        stakeDevKingz.unstakeNFT(tokenIds);

        // Verify NFT returned to USER
        assertEq(devKingz.ownerOf(tokenId), USER);
        assertEq(devKingz.balanceOf(USER), 1);
        assertEq(devKingz.balanceOf(address(stakeDevKingz)), 0);

        // Verify vault entry cleared
        (address owner) = stakeDevKingz.vault(tokenId);
        assertEq(owner, address(0));

        // Verify total staked count decremented
        assertEq(stakeDevKingz.totalStakedDevKingz(), initialCount - 1);
        vm.stopPrank();
    }

    modifier mintMultipleNFTs() {
        // Mint 3 NFTs to USER
        vm.startPrank(USER);
        vm.deal(USER, STARTING_USER_BALANCE);
        uint256 requestId1 = devKingz.requestNft{value: mintFee}();
        uint256 requestId2 = devKingz.requestNft{value: mintFee}();
        uint256 requestId3 = devKingz.requestNft{value: mintFee}();
        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(requestId1, address(devKingz));
        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(requestId2, address(devKingz));
        VRFCoordinatorV2_5Mock(address(vrfCoordinator)).fulfillRandomWords(requestId3, address(devKingz));
        vm.stopPrank();
        _;
    }

    modifier stakeMultipleNFTs() {
        vm.startPrank(USER);
        devKingz.setApprovalForAll(address(stakeDevKingz), true);
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        stakeDevKingz.stakeNFTs(tokenIds);
        vm.stopPrank();
        _;
    }

    function testUnstakeMultipleNFTs() external mintMultipleNFTs stakeMultipleNFTs {
        vm.startPrank(USER);
        // Unstake tokenId 0 and 2
        uint256[] memory unstakeIds = new uint256[](2);
        unstakeIds[0] = 0;
        unstakeIds[1] = 2;

        stakeDevKingz.unstakeNFT(unstakeIds); // Unstake tokenId 0 and 2

        // Verify tokenId 0 and 2 returned to USER show tokenIds in cosole log
        assertEq(devKingz.ownerOf(0), USER);
        assertEq(devKingz.ownerOf(2), USER);

        // Verify tokenId 1 still staked
        assertEq(stakeDevKingz.totalStakedDevKingz(), 1); // Only tokenId 1 should remain staked
        assertEq(devKingz.ownerOf(1), address(stakeDevKingz)); // tokenId 1 should still be owned by the staking contract

        console.log("Unstaked tokenId:", uint256(0));
        console.log("Unstaked tokenId:", uint256(2));
        console.log("TokenId 1 should still be staked.:", stakeDevKingz.totalStakedDevKingz());
        vm.stopPrank();
    }

    function testUnstakeRevertsWhenNotOwner() external mintDevKingzNFT stakeDevKingzNFTMod {
        uint256 tokenId = 0; // Token minted and staked by modifiers
        // SCAMMER tries to unstake USER's NFT
        vm.startPrank(SCAMMER);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        vm.expectRevert(abi.encodeWithSelector(StakeDevKingz.StakeDevKingz__NotTokenOwner.selector, SCAMMER, tokenId));
        stakeDevKingz.unstakeNFT(tokenIds);
        vm.stopPrank();
    }

    function testUnstakeRevertsWhenTokenNotStaked() external mintDevKingzNFT {
        uint256 tokenId = 0; // Token minted but NOT staked by USER
        // Don't stake it

        vm.startPrank(USER);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        vm.expectRevert(abi.encodeWithSelector(StakeDevKingz.StakeDevKingz__TokenNotStaked.selector, tokenId));
        stakeDevKingz.unstakeNFT(tokenIds);
        vm.stopPrank();
    }

    function testUnstakeWithZeroRewards() external mintDevKingzNFT stakeDevKingzNFTMod {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0; // Token minted and staked by modifiers
        // Unstake immediately (0 time elapsed = 0 rewards)
        vm.prank(USER);
        stakeDevKingz.unstakeNFT(tokenIds);
        // Verify no RewardsClaimed event (tested by not expecting it)
        assertEq(devKingz.ownerOf(tokenIds[0]), USER);
        assertEq(stakeDevKingz.calculateRewards(tokenIds[0]), 0);
        console.log("Claimable rewards:", stakeDevKingz.calculateRewards(tokenIds[0]));
        console.log("DevKingz NFT unstaked:", tokenIds[0]);
    }

    modifier advanceTime(uint256 secondsToAdvance) {
        vm.warp(block.timestamp + secondsToAdvance);
        _;
    }

    function testCalculateRewards() external mintDevKingzNFT stakeDevKingzNFTMod advanceTime(1 days) {
        uint256 distributeAmount = 86400 * 1e18;
        stakeDevKingz.distributeRewards(distributeAmount);
        uint256 expectedRewards = distributeAmount;
        uint256 actualRewards = stakeDevKingz.calculateRewards(0);
        assertEq(actualRewards, expectedRewards);
        console.log("Expected rewards:", expectedRewards);
        console.log("Actual rewards:", actualRewards);
    }

    function testClaimRewardsAfterDistribution() external mintDevKingzNFT stakeDevKingzNFTMod {
        uint256 distributeAmount = 86400 * 1e18;

        // Admin distributes rewards — this is what actually credits stakers
        stakeDevKingz.distributeRewards(distributeAmount);

        // 1 NFT staked = 100% of distribution
        uint256 actualRewards = stakeDevKingz.calculateRewards(0);
        assertEq(actualRewards, distributeAmount);

        // Now claim and verify token balance
        vm.prank(USER);
        stakeDevKingz.claimRewards();
        assertEq(kingzToken.balanceOf(USER), distributeAmount);
    }

    function testPendingRewardsAfterDistribution() external mintDevKingzNFT stakeDevKingzNFTMod {
        uint256 distributeAmount = 10000 * 1e18;

        // Only 1 NFT staked so it gets 100% of distribution
        stakeDevKingz.distributeRewards(distributeAmount);

        uint256 actualRewards = stakeDevKingz.calculateRewards(0);
        assertEq(actualRewards, distributeAmount); // 1 NFT = 100% share
    }

    function testPendingRewardsForMultipleNFTs() external mintMultipleNFTs stakeMultipleNFTs {
        uint256 distributeAmount = 10000 * 1e18;
        uint256 expectedRewardsPerNFT = distributeAmount / 3; // split across 3 staked NFTs

        // Distribute once BEFORE checking all tokens
        stakeDevKingz.distributeRewards(distributeAmount);

        for (uint256 tokenId = 0; tokenId < 3; tokenId++) {
            uint256 actualRewards = stakeDevKingz.calculateRewards(tokenId);
            assertEq(actualRewards, expectedRewardsPerNFT);
            console.log("Expected rewards for tokenId", tokenId, ":", expectedRewardsPerNFT);
            console.log("Actual rewards for tokenId", tokenId, ":", actualRewards);
        }
    }

    function testUnstakeCalculatesCorrectRewards() external mintDevKingzNFT stakeDevKingzNFTMod advanceTime(1 days) {
        uint256 distributeAmount = 10000 * 1e18;
        stakeDevKingz.distributeRewards(distributeAmount);
        // Calculate expected rewards based on time staked and distribution
        uint256 expectedRewards = distributeAmount;
        vm.startPrank(USER);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0; // Token minted and staked by modifiers
        stakeDevKingz.unstakeNFT(tokenIds);
        uint256 actualRewards = kingzToken.balanceOf(USER);
        assertEq(actualRewards, expectedRewards);
        console.log("Expected rewards:", expectedRewards);
        console.log("Actual rewards:", actualRewards);
        vm.stopPrank();
    }

    function testCannotUnstakeSameTokenTwice() external mintMultipleNFTs stakeMultipleNFTs {
        vm.startPrank(USER);
        vm.deal(USER, STARTING_USER_BALANCE);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        stakeDevKingz.unstakeNFT(tokenIds);
        vm.expectRevert(abi.encodeWithSelector(StakeDevKingz.StakeDevKingz__TokenNotStaked.selector, tokenIds[0]));
        stakeDevKingz.unstakeNFT(tokenIds);
        vm.stopPrank();
    }

    function testRewardPrecisionWithUnevenDistribution() external mintMultipleNFTs stakeMultipleNFTs {
        uint256 distributeAmount = 100e18;
        stakeDevKingz.distributeRewards(distributeAmount);

        uint256 r0 = stakeDevKingz.calculateRewards(0);
        uint256 r1 = stakeDevKingz.calculateRewards(1);
        uint256 r2 = stakeDevKingz.calculateRewards(2);

        uint256 totalClaimed = r0 + r1 + r2;

        // Dust loss is expected — total claimed will be within 1 token unit of distributed
        assertApproxEqAbs(totalClaimed, distributeAmount, 1e18);
        // Each token gets equal share
        assertEq(r0, r1);
        assertEq(r1, r2);
    }

    function testDistributeRevertsWhenNothingStaked() external {
        vm.expectRevert(abi.encodeWithSelector(StakeDevKingz.StakeDevKingz__NoStakedNFTs.selector));
        stakeDevKingz.distributeRewards(100e18);
    }

    // New Tests -> need to test edge cases around distribution and claiming, especially with multiple NFTs and multiple distributions before claiming

    // distributeRewards access control
    function testDistributeRevertsForNonAdmin() external mintDevKingzNFT stakeDevKingzNFTMod {
        vm.prank(USER);
        vm.expectRevert();
        stakeDevKingz.distributeRewards(100e18);
    }

    // claimRewards with nothing staked — silent no-op
    function testClaimRewardsWithNothingStakedDoesNothing() external {
        vm.prank(USER);
        stakeDevKingz.claimRewards();
        assertEq(kingzToken.balanceOf(USER), 0);
    }


    // multiple distributions accumulate correctly before a single claim
    function testMultipleDistributionsAccumulate() external mintDevKingzNFT stakeDevKingzNFTMod {
        stakeDevKingz.distributeRewards(100e18);
        stakeDevKingz.distributeRewards(200e18);
        assertEq(stakeDevKingz.calculateRewards(0), 300e18);
        vm.prank(USER);
        stakeDevKingz.claimRewards();
        assertEq(kingzToken.balanceOf(USER), 300e18);
    }

    // restake after unstake gets no phantom rewards from before
    function testRestakeAfterUnstakeNoPhantomRewards() external mintDevKingzNFT stakeDevKingzNFTMod {
        stakeDevKingz.distributeRewards(100e18);
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        vm.prank(USER);
        stakeDevKingz.unstakeNFT(ids); // claims 100e18
        // restake
        vm.startPrank(USER);
        devKingz.setApprovalForAll(address(stakeDevKingz), true);
        stakeDevKingz.stakeNFTs(ids);
        vm.stopPrank();
        // distribute again
        stakeDevKingz.distributeRewards(50e18);
        assertEq(stakeDevKingz.calculateRewards(0), 50e18); // only new distribution
    }

    // unstake empty array
    function testUnstakeRevertsWithEmptyArray() external {
        vm.prank(USER);
        uint256[] memory empty = new uint256[](0);
        vm.expectRevert(abi.encodeWithSelector(StakeDevKingz.StakeDevKingz__EmptyTokenArray.selector));
        stakeDevKingz.unstakeNFT(empty);
    }
}

