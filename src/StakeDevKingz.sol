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
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract StakeDevKingz is AccessControl, ReentrancyGuard, IERC721Receiver {
    // State Variables
    DevKingz public devKingz;
    KingzToken public kingzToken;
    uint256 public totalStakedDevKingz;
    uint256 public rewardPerDevKingzStored;
    uint256 public lastDistributionTime;

    struct StakerInfo {
        address owner;
        uint256 lastUpdateTime;
    }

    // Mappings
    mapping(uint256 => StakerInfo) public vault; // tokenId => Staker
    mapping(address => uint256[]) private ownerToStakedTokens;
    mapping(uint256 => uint256) public tokenRewardPerDevKingzPaid; // tokenId => rewardPerDevKingz at last update
    mapping(uint256 => uint256) public tokenRewards; // tokenId => accumulated rewards

    // Events
    event NFTStaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event RewardsClaimed(address indexed owner, uint256 amount);
    // added refactor
    event RewardsDistributed(uint256 amount, uint256 rewardPerDevKingzStored); // Emitted when rewards are distributed to stakers

    // Custom Errors
    error StakeDevKingz__InsufficientRewardBalance(uint256 required, uint256 available);
    error StakeDevKingz__NotTokenOwner(address caller, uint256 tokenId);
    error StakeDevKingz__TokenNotStaked(uint256 tokenId);
    error StakeDevKingz__EmptyTokenArray();
    error StakeDevKingz__NotTokenContract();
    error StakeDevKingz__TokenAlreadyStaked(uint256 tokenId);
    // added refactor errors
    error StakeDevKingz__NoStakedNFTs();
    error StakeDevKingz__ZeroAmount(); // For zero reward distribution earnings

    constructor(address _devKingzAddress, address _kingzTokenAddress) {
        devKingz = DevKingz(_devKingzAddress);
        kingzToken = KingzToken(_kingzTokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * This contract allows users to stake their DevKingz NFTs and earn KINGZ token rewards.
     */
    function stakeNFTs(uint256[] calldata tokenIds) external nonReentrant {
        _stakeNFTs(tokenIds);
    }

    function unstakeNFT(uint256[] calldata tokenIds) external nonReentrant {
        _unstakeNFT(tokenIds);
    }

    /**
     * @notice Claims all pending KINGZ rewards for caller's staked NFTs
     */
    function claimRewards() external nonReentrant {
        uint256 claimableRewards = 0;
        uint256[] memory stakedTokens = ownerToStakedTokens[msg.sender];

        for (uint256 i = 0; i < stakedTokens.length; ++i) {
            uint256 tokenId = stakedTokens[i];

            // Snapshot accumulated rewards before resetting
            _updateReward(tokenId);
            claimableRewards += tokenRewards[tokenId];

            // Reset accumulated rewards for this token
            tokenRewards[tokenId] = 0;
        }

        if (claimableRewards > 0) {
            // Transfer from contract balance (minted at distribution time)
            kingzToken.transfer(msg.sender, claimableRewards);
            emit RewardsClaimed(msg.sender, claimableRewards);
        }
    }

    /**
     * @notice Distributes a fixed amount of KINGZ split pro-rata across all staked NFTs
     * @param amount Total amount of KINGZ to distribute among stakers.
     */
    function distributeRewards(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (totalStakedDevKingz == 0) revert StakeDevKingz__NoStakedNFTs();
        if (amount == 0) revert StakeDevKingz__ZeroAmount();

        // Update the global accumulator — scaled by 1e18 to preserve precision
        rewardPerDevKingzStored += (amount * 1e18) / totalStakedDevKingz;
        lastDistributionTime = block.timestamp;

        // Mint the total reward amount into this contract to be claimed later
        kingzToken.mint(address(this), amount);

        emit RewardsDistributed(amount, rewardPerDevKingzStored);
    }

    /**
     * @notice Returns the pending rewards for a given tokenId
     */
    function calculateRewards(uint256 tokenId) external view returns (uint256) {
        return _earned(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _stakeNFTs(uint256[] calldata tokenIds) internal {
        // Prevents staking with empty array
        if (tokenIds.length == 0) revert StakeDevKingz__EmptyTokenArray();

        // Implementation for staking DevKingz NFTs
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 tokenId = tokenIds[i];
            unchecked {
                ++i;
            }

            // Check if token is already staked
            if (vault[tokenId].owner != address(0)) revert StakeDevKingz__TokenAlreadyStaked(tokenId);

            // Snapshot accumulated Before staking to ensure new stakers don't earn rewards for past distributions.
            _updateReward(tokenId);

            // Record the staking
            vault[tokenId] = StakerInfo({owner: msg.sender, lastUpdateTime: block.timestamp});

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

    // Implementation for unstaking DevKingz NFTs and claiming rewards
    function _unstakeNFT(uint256[] calldata tokenIds) internal {
        uint256 length = tokenIds.length;
        if (length == 0) revert StakeDevKingz__EmptyTokenArray();

        for (uint256 i = 0; i < length;) {
            uint256 tokenId = tokenIds[i];

            StakerInfo memory staker = vault[tokenId];

            // Validate ownership per token
            if (staker.owner == address(0)) revert StakeDevKingz__TokenNotStaked(tokenId);
            if (staker.owner != msg.sender) revert StakeDevKingz__NotTokenOwner(msg.sender, tokenId);

            // Calculate pending rewards
            _updateReward(tokenId);
            uint256 pendingRewards = tokenRewards[tokenId];
            tokenRewards[tokenId] = 0; // Reset rewards for this token

            // CEI Pattern: State changes BEFORE external calls
            delete vault[tokenId];
            --totalStakedDevKingz;

            // Transfer NFT back to owner
            _removeTokenFromOwnerArray(msg.sender, tokenId);
            emit NFTUnstaked(msg.sender, tokenId, block.timestamp);
            devKingz.safeTransferFrom(address(this), msg.sender, tokenId);

            // Transfer rewards if any (after state changes)
            if (pendingRewards > 0) {
                kingzToken.transfer(msg.sender, pendingRewards);
                emit RewardsClaimed(msg.sender, pendingRewards);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _earned(uint256 tokenId) internal view returns (uint256) {
        return tokenRewards[tokenId] + (rewardPerDevKingzStored - tokenRewardPerDevKingzPaid[tokenId] ) / 1e18;
    }

    function _updateReward(uint256 tokenId) internal {
        tokenRewards[tokenId] = _earned(tokenId);
        // snapshot current accumulator
        tokenRewardPerDevKingzPaid[tokenId] = rewardPerDevKingzStored;
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

    // Added for testing and transparency: Get all staked tokenIds for a specific owner
    function getStakedTokens(address owner) external view returns (uint256[] memory) {
        return ownerToStakedTokens[owner];
    }

    // Added for testing and transparency: Get staker info for a specific tokenId
    function getStakerInfo(uint256 tokenId)
        external
        view
        returns (address owner, uint256 lastUpdateTime, uint256 pendingRewards)
    {
        StakerInfo storage stakerInfo = vault[tokenId];
        owner = stakerInfo.owner;
        lastUpdateTime = stakerInfo.lastUpdateTime;
        pendingRewards = _earned(tokenId);
    }

    // Required override for receiving ERC721 tokens
    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
