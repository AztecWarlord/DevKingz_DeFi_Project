// SPDX-License-Identifier: MIT

// This is the Staking rewards token for the DevKingz staking project.

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.19;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title Kingz Token (KINGZ)
 * @author Michael Vargas
 * Minting (Stability Mechanism): 
 * Collateral Type: Crypto
 *
 * This is the contract meant to be owned by StakeDevKingz. It is a ERC20 token that can be minted and burned by the StakeDevKingz smart contract.
 */

contract KingzToken is ERC20Burnable, Ownable {
    error KingzToken__MustBeMoreThanZero();
    error KingzToken__BurnAmountExceedsBalance();
    error KingzToken__NotZeroAddress();

    constructor(address initialOwner) ERC20("KingzToken", "KINGZ") Ownable(initialOwner) {
        if (initialOwner == address(0)) {
            revert KingzToken__NotZeroAddress();
        }
        _transferOwnership(initialOwner);
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert KingzToken__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert KingzToken__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert KingzToken__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert KingzToken__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}