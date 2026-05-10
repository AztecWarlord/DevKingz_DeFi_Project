// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {StakeDevKingz} from "../../src/StakeDevKingz.sol";
import {DeployMockDevKingz} from "../../script/DeployMockDevKingz.s.sol";
import {DeployStakeDevKingz} from "../../script/DeployStakeDevKingz.s.sol";
import {DeployKingzToken} from "../../script/DeployKingzToken.s.sol";
import {DevKingz} from "../mocks/MockDevKingzNFT.sol";
import {KingzToken} from "../../src/kingzToken.sol";
// import {DevKingz} from "../../src/devKingz.sol";
// import {DeployDevKingz} from "../../script/DeployDevKingz.s.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

// This contract will test the functionality of the StakeDevKingz smart contract.
contract StakeDevKingzTest is Test {
    StakeDevKingz public stakeDevKingz;
    DevKingz public devKingz;
    KingzToken public kingz;

    address public initialOwner = makeAddr("owner");

    struct StakerInfo {
        address owner;
        uint256[] tokenIds;
        uint256 rewards;
        uint256 lastUpdateTime;
    }

    address public USER = makeAddr("user");
    address public SCAMMER = makeAddr("scammer");
    address public ADMIN = makeAddr("admin");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant CONTRACT_BALANCE = 10 ether;
    uint256 internal constant REWARD_RATE_PER_SECOND = 1e18; // 1
    address public devKingzAddress;
    string public tokenUri = "ipfs://exampleTokenUri";

    mapping(uint256 => StakerInfo) private vault; // tokenId => Staker

    event NFTStaked(address indexed owner, uint256 indexed tokenIds, uint256 timestamp);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenIds, uint256 timestamp);
    event RewardsClaimed(address indexed owner, uint256 amount);

    function setUp() external {
        DeployMockDevKingz mockDeployer = new DeployMockDevKingz();
        devKingz = mockDeployer.deployMockDevKingz();

        DeployStakeDevKingz stakeDeployer = new DeployStakeDevKingz();
        (stakeDevKingz,kingz) = stakeDeployer.deployStakeDevKingz(address(devKingz));

        assertEq(kingz.owner(), address(stakeDevKingz));
    }

    // function setUp() external {
    //     DeployMockDevKingz deployer = new DeployMockDevKingz();
    //     DeployStakeDevKingz deployStake = new DeployStakeDevKingz();
    //     DeployKingzToken deployKingz = new DeployKingzToken();
    //     devKingz = deployer.deployMockDevKingz();
    //     (stakeDevKingz,) = deployStake.deployStakeDevKingz(address(devKingz), address(stakeDevKingz));
    // }

    // Mints a DevKingz NFT to the USER
    modifier mintDevKingzNFT() {
        vm.startPrank(USER);
        vm.deal(USER, STARTING_USER_BALANCE);
        devKingz.mintNft(tokenUri);
        vm.stopPrank();
        _;
    }

    // Tests staking functionality
    function testStakeNFT() external mintDevKingzNFT {
        vm.startPrank(USER);

        // Approve the staking contract to transfer the user's NFTs
        devKingz.setApprovalForAll(address(stakeDevKingz), true);

        // Stake the minted NFT (tokenId 0)
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0; // Explicitly set tokenId
        uint256 stakingTime = block.timestamp;
        uint256 initialCount = stakeDevKingz.totalStakedDevKingz();
        stakeDevKingz.stakeNFTs(tokenIds);

        // Verify NFT transferred to staking contract
        assertEq(devKingz.balanceOf(address(stakeDevKingz)), 1);
        assertEq(devKingz.balanceOf(USER), 0);

        // Verify vault updated
        (address owner, uint256 lastUpdateTime) = stakeDevKingz.vault(0);
        assertEq(lastUpdateTime, stakingTime);
        assertEq(owner, USER);
        assertEq(stakeDevKingz.totalStakedDevKingz(), initialCount + 1);
        console.log("Last update time recorded in vault:", lastUpdateTime);
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
        devKingz.setApprovalForAll(address(stakeDevKingz), true);

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
        devKingz.mintNft(tokenUri);
        devKingz.mintNft(tokenUri);

        devKingz.setApprovalForAll(address(stakeDevKingz), true);

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        stakeDevKingz.stakeNFTs(tokenIds);

        // Verify all vault entries

        uint256 mintedDevs = 3;
        for (uint256 i = 0; i < mintedDevs; i++) {
            (address owner, uint256 lastUpdateTime) = stakeDevKingz.vault(i);
            assertEq(owner, USER);
            assertEq(lastUpdateTime, block.timestamp);
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
        (address owner, uint256 lastUpdateTime) = stakeDevKingz.vault(tokenId);
        assertEq(owner, address(0));
        assertEq(lastUpdateTime, 0);

        // Verify total staked count decremented
        assertEq(stakeDevKingz.totalStakedDevKingz(), initialCount - 1);
        vm.stopPrank();
    }

    modifier mintMultipleNFTs() {
        // Mint 3 NFTs to USER
        vm.startPrank(USER);
        vm.deal(USER, STARTING_USER_BALANCE);
        devKingz.mintNft(tokenUri);
        devKingz.mintNft(tokenUri);
        devKingz.mintNft(tokenUri);
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

    // function testUnstakeWithZeroRewards() external {
    //     uint256 tokenId = _mintNFT(USER);
    //     _stakeNFT(USER, tokenId);

    //     // Unstake immediately (0 time elapsed = 0 rewards)
    //     vm.prank(USER);
    //     stakeDevKingz.unstakeNFT(tokenId);

    //     // Verify no RewardsClaimed event (tested by not expecting it)
    //     assertEq(devKingz.ownerOf(tokenId), USER);
    // }

    modifier advanceTime(uint256 secondsToAdvance) {
        vm.warp(block.timestamp + secondsToAdvance);
        _;
    }

    // function testUnstakeCalculatesCorrectRewards() external {
    // }

    // function testCannotUnstakeSameTokenTwice() external {
    // }
}

