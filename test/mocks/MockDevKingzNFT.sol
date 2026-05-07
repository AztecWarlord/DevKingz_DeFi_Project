// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract DevKingz is ERC721 {
    // Mock DevKingz NFT contract implementation

    uint256 public _exists;

    error DevKingz__TokenUriNotFound();

    mapping(uint256 => string) private s_tokenIdToUri;
    uint256 private s_tokenCounter;

    constructor() ERC721("DevKingz", "DKZ") {
        s_tokenCounter = 0;
    }

    function mintNft(string memory tokenUri) public {
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Reverts if token doesn't exist
        return s_tokenIdToUri[tokenId];
    }
}
