// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721, Ownable {
    struct ListedNFT {
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => ListedNFT) private _activeItems;

    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId);
    event NFTListingUpdated(uint256 indexed tokenId, uint256 newPrice);
    event NFTListingCancelled(uint256 indexed tokenId);
    event NFTBought(uint256 indexed tokenId, address indexed buyer, uint256 price);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}
// list nft in the market place
    function listNFT(uint256 tokenId, uint256 price) external onlyOwner {
        require(!_activeItems[tokenId].isListed, "NFT is already listed");
        _activeItems[tokenId] = ListedNFT(price, true);
        emit NFTListed(tokenId, price);
    }
// updare the list 
    function updateListing(uint256 tokenId, uint256 price) external onlyOwner {
        require(_activeItems[tokenId].isListed, "NFT is not listed");
        _activeItems[tokenId].price = price;
        emit NFTListingUpdated(tokenId, price);
    }
// unlist NFT 
    function unlistNFT(uint256 tokenId) external onlyOwner {
        require(_activeItems[tokenId].isListed, "NFT is not listed");
        delete _activeItems[tokenId];
        emit NFTUnlisted(tokenId);
    }
// buy NFT
    function buyNFT(uint256 tokenId) external payable {
        require(_activeItems[tokenId].isListed, "NFT is not listed for sale");
        require(msg.value == _activeItems[tokenId].price, "Incorrect amount sent");

        address seller = ownerOf(tokenId);
        address buyer = msg.sender;

        _transfer(seller, buyer, tokenId);
        _activeItems[tokenId].isListed = false;

// Transfer funds to the seller
        payable(seller).transfer(msg.value);

        emit NFTBought(tokenId, buyer, msg.value);
    }
}
