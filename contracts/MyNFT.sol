// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721, Ownable {
    struct ListedNFT {
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => ListedNFT) private _activeItem;

    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /**
     * @dev Function to list an NFT for sale.
     * @param tokenId The ID of the NFT to be listed.
     * @param price The sale price of the NFT.
     */
    function listNFT(uint256 tokenId, uint256 price) external onlyOwner {
        require(!_activeItem[tokenId].isListed, "NFT is already listed");
        _activeItem[tokenId] = ListedNFT(price, true);
        emit NFTListed(tokenId, price);
    }

    /**
     * @dev Function to update the listing of an NFT.
     * @param tokenId The ID of the NFT to be updated.
     * @param price The new sale price of the NFT.
     */
    function updateListing(uint256 tokenId, uint256 price) external onlyOwner {
        require(_activeItem[tokenId].isListed, "NFT is not listed");
        _activeItem[tokenId].price = price;
        emit NFTListed(tokenId, price); // Emits the same event as listing for simplicity
    }

    /**
     * @dev Function to unlist an NFT for sale.
     * @param tokenId The ID of the NFT to be unlisted.
     */
    function unlistNFT(uint256 tokenId) external onlyOwner {
        require(_activeItem[tokenId].isListed, "NFT is not listed");
        delete _activeItem[tokenId];
        emit NFTUnlisted(tokenId);
    }

    /**
     * @dev Function to buy an NFT listed for sale.
     * @param tokenId The ID of the NFT to be purchased.
     */
    function buyNFT(uint256 tokenId) external payable {
        ListedNFT storage nft = _activeItem[tokenId];
        require(nft.isListed, "NFT is not listed for sale");
        require(msg.value == nft.price, "Incorrect amount sent");

        address seller = ownerOf(tokenId);
        address buyer = msg.sender;

        _transfer(seller, buyer, tokenId);
        nft.isListed = false;

        // Transfer funds to the seller
        payable(seller).transfer(msg.value);
    }

    /**
     * @dev Function to get the details of an NFT listed for sale.
     * @param tokenId The ID of the NFT.
     * @return Details of the listed NFT.
     */
    function getActiveItem(uint256 tokenId) public view returns (ListedNFT memory) {
        return _activeItem[tokenId];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * Changes are made to transferFrom to prevent transfers of a listed NFT.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721) {
        require(!_activeItem[tokenId].isListed, "You can't transfer a listed NFT");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * Changes are made to safeTransferFrom to prevent transfers of a listed NFT.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721) {
        require(!_activeItem[tokenId].isListed, "You can't transfer a listed NFT");
        _safeTransfer(from, to, tokenId, data);
    }
}
