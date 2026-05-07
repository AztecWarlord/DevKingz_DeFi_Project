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

// import {DevKingz} from "./devKingz.sol";
import {DevKingz} from "../test/mocks/MockDevKingzNFT.sol";
import {KingzToken} from "./kingzToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
using SafeERC20 for IERC20;

contract StakeDevKingz is AccessControl, ReentrancyGuard, IERC721Receiver {
    // State Variables
    DevKingz public devKingz;
    IERC20 public kingzToken;
    uint256 public totalStakedDevKingz;
    uint256 public constant REWARD_RATE_PER_SECOND = 1e18; // 1 KINGZ token per second

    struct StakerInfo {
        address owner;
        uint256 lastUpdateTime;
    }

    // Mappings
    mapping(uint256 => StakerInfo) public vault; // tokenId => Staker
    mapping(address => uint256[]) private ownerToStakedTokens;

    // Events
    event NFTStaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event RewardsClaimed(address indexed owner, uint256 amount);

    // Custom Errors
    error StakeDevKingz__InsufficientRewardBalance(uint256 required, uint256 available);
    error StakeDevKingz__NotTokenOwner(address caller, uint256 tokenId);
    error StakeDevKingz__TokenNotStaked(uint256 tokenId);
    error StakeDevKingz__EmptyTokenArray();
    error StakeDevKingz__NotTokenContract();
    error StakeDevKingz__TokenAlreadyStaked(uint256 tokenId);

    constructor(address _devKingzAddress, address _kingzTokenAddress) {
        devKingz = DevKingz(_devKingzAddress);
        kingzToken = IERC20(_kingzTokenAddress);
    }

    /** This contract allows users to stake their DevKingz NFTs and earn KINGZ token rewards. */
    function stakeNFTs(uint256[] calldata tokenIds) external nonReentrant{
        _stakeNFTs(tokenIds);
    }

    function _stakeNFTs(uint256[] calldata tokenIds) internal {
        // Prevents staking with empty array
        if (tokenIds.length == 0) revert StakeDevKingz__EmptyTokenArray();

        // Implementation for staking DevKingz NFTs
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            // Check if token is already staked
            if (vault[tokenId].owner != address(0)) revert StakeDevKingz__TokenAlreadyStaked(tokenId);

            // Record the staking
            vault[tokenId] = StakerInfo({
                owner: msg.sender,
                lastUpdateTime: block.timestamp
            });
            
            // Add to owner's staked tokens
            ownerToStakedTokens[msg.sender].push(tokenId);
            
            // Increment total staked count
            ++totalStakedDevKingz;
            
            // Transfer the NFT to this contract (validates ownership)
            devKingz.safeTransferFrom(msg.sender, address(this), tokenId);

            // Emit event for each staked token
            emit NFTStaked(msg.sender, tokenId, block.timestamp);
        }
    }

    function unstakeNFT(uint256[] calldata tokenIds) public  nonReentrant {
        _unstakeNFT(tokenIds);
    }

    function _unstakeNFT(uint256[] calldata tokenIds) internal {
        uint256 length = tokenIds.length;
        if (length == 0) revert StakeDevKingz__EmptyTokenArray();

        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = tokenIds[i];

            StakerInfo memory staker = vault[tokenId];

            // Validate ownership per token
            if (staker.owner == address(0)) revert StakeDevKingz__TokenNotStaked(tokenId);
            if (staker.owner != msg.sender) revert StakeDevKingz__NotTokenOwner(msg.sender, tokenId);

            // Calculate pending rewards
            uint256 pendingRewards = _calculateRewards(tokenId);

            // CEI Pattern: State changes BEFORE external calls
            delete vault[tokenId];
            --totalStakedDevKingz;

            // Transfer NFT back to owner
            _removeTokenFromOwnerArray(msg.sender, tokenId);
            devKingz.safeTransferFrom(address(this), msg.sender, tokenId);
            emit NFTUnstaked(msg.sender, tokenId, block.timestamp);

            // Transfer rewards if any (after state changes)
            if (pendingRewards > 0) {
                uint256 contractBalance = kingzToken.balanceOf(address(this));
                if (contractBalance < pendingRewards) {
                    revert StakeDevKingz__InsufficientRewardBalance(pendingRewards, contractBalance);
                }
                kingzToken.safeTransfer(msg.sender, pendingRewards);
                emit RewardsClaimed(msg.sender, pendingRewards);
            }

            unchecked { ++i; }
        }
    }



    function depositRewards(uint256 amount) external {
        // Implementation for depositing KINGZ tokens into the contract for rewards
        kingzToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function claimRewards() external nonReentrant{
    // Implementation for claiming KINGZ token rewards
        uint256 totalRewards = 0;
        uint256[] memory stakedTokens = ownerToStakedTokens[msg.sender];
        
        for (uint256 i = 0; i < stakedTokens.length; ++i) {
            uint256 tokenId = stakedTokens[i];
            uint256 rewards = _calculateRewards(tokenId);
            if (rewards > 0) {
                totalRewards += rewards;
                vault[tokenId].lastUpdateTime = block.timestamp; // Update last claim time
            }
        }
        
        if (totalRewards > 0) {
            uint256 contractBalance = kingzToken.balanceOf(address(this));
            if (contractBalance < totalRewards) {
                revert StakeDevKingz__InsufficientRewardBalance(totalRewards, contractBalance);
            }
            
            kingzToken.safeTransfer(msg.sender, totalRewards);
            emit RewardsClaimed(msg.sender, totalRewards);
        }
    }

    function calculateRewards(uint256 tokenId) external view returns (uint256) {
        // Implementation for calculating rewards for a owner
        return _calculateRewards(tokenId);
    }

    function _calculateRewards(uint256 tokenId) internal view returns (uint256) {
        StakerInfo storage stakerInfo = vault[tokenId];
        if (stakerInfo.owner == address(0)) {
            return 0; // Not staked
        }
        uint256 stakingDuration = block.timestamp - stakerInfo.lastUpdateTime;
        return stakingDuration * REWARD_RATE_PER_SECOND;
    }

    function _removeTokenFromOwnerArray(address owner, uint256 tokenId) internal {
        uint256[] storage stakedTokens = ownerToStakedTokens[owner];
        uint256 length = stakedTokens.length;
        
        for (uint256 i = 0; i < length; i++) {
            if (stakedTokens[i] == tokenId) {
                // Move last element to this position and pop
                stakedTokens[i] = stakedTokens[length - 1];
                stakedTokens.pop();
                break;
            }
        }
    }

    function getStakedTokens(address owner) external view returns (uint256[] memory) {
        return ownerToStakedTokens[owner];
    }


    function getStakerInfo(uint256 tokenId) external view returns (address owner, uint256 lastUpdateTime, uint256 pendingRewards) {
        StakerInfo storage stakerInfo = vault[tokenId];
        owner = stakerInfo.owner;
        lastUpdateTime = stakerInfo.lastUpdateTime;
        pendingRewards = _calculateRewards(tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}