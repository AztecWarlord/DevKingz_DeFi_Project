# DevKingz DeFi Project

DevKingz DeFi is an NFT staking app where holders stake DevKingz NFTs to earn `KINGZ` token rewards. The project combines NFTs, DeFi mechanics, and GameFi-inspired progression.

## Overview

DevKingz DeFi currently includes:

- **DevKingz NFTs**: Tokenized digital assets that power participation.
- **Staking Contract**: Stake NFTs to accumulate reward tokens.
- **KINGZ Token**: ERC20 reward token for ecosystem incentives.
- **DevKingz Vault (Planned)**: Future extension for expanded utility.

## Vision

The goal is to unify the DevKingz NFT project with a gamified DeFi ecosystem and build long-term, real utility through sustainable token incentives and product expansion.

## Features
- Chainlink VRF for randomized NFT minting.
- Stake DevKingz NFTs for yield in `KINGZ`.
- ERC20-based rewards distribution.
- Foundry-native smart contract development and testing.
- Deployment scripts for core contracts.

## Tech Stack

- **Solidity** for smart contracts
- **Foundry** (`forge`, `cast`, `anvil`) for build, testing, and scripting
- **OpenZeppelin Contracts** for audited contract primitives
- **Chainlink Brownie Contracts** (library dependency) utilizes Chainlink VRF to randomize NFT minting.
- **Solmate** (library dependency)

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation

```bash
git clone <your-repo-url>
cd DevKingz_DeFi_Project
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test -vv
```

## Usage

### Local Development

Start a local node:

```bash
anvil
```

## Roadmap

- [x] Core NFT contract
- [x] KINGZ rewards token contract
- [x] NFT staking contract
- [ ] DevKingz Vault
- [ ] Expanded GameFi mechanics
- [ ] Frontend dApp integration

## Security

- This project is under active development and has not been declared production-audited.
- Do not use production private keys in local scripts.
- Report security concerns privately to the project maintainer before public disclosure.

## License

No License listed.

## Acknowledgments

- Foundry
- ChainlinkVRF
- OpenZeppelin
- Cyfrin/foundry-devops

##
[![Michael Vargas Linkedin](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/michael-vargas-a5b51b223/)
