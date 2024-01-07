// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    // contract inherits from ERC721, ERC721Enumerable, ERC721URIStorage and Ownable contracts
    using Counters for Counters.Counter;

    struct ListedNFT {
        // struct to store NFT details for sale
        address seller; // seller address
        uint256 price; // sale price
        string url; // NFT URI
    }

    mapping(uint256 => ListedNFT) private _activeItem; // map NFT tokenId to ListedNFT struct, _activeItem store array of item listed into marketplace

    Counters.Counter private _tokenIdCounter; // counter to generate unique token ids

    constructor() ERC721("MyNFT", "MNFT") {} // constructor to initialize the contract with name "MyNFT" and symbol "MNFT"

    /**
     * @dev Emitted when the listing of an NFT is cancelled.
     * @param tokenId The unique identifier of the cancelled NFT listing.
     * @param caller The address of the caller who cancelled the NFT listing.
    */
    event NftListingCancelled(
        uint256 indexed tokenId,
        address indexed caller
    );
 

    /**
    * @dev Emitted when an NFT is listed for sale.
    * @param tokenId The unique identifier of the listed NFT.
    * @param buyer The address of the buyer who listed the NFT.
    * @param price The price at which the NFT is listed for sale.
    */
    event NftListed(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    ); 

    /**
     * @dev Emitted when a new NFT is created.
     * @param owner The address of the owner of the newly created NFT.
     * @param tokenId The unique identifier of the newly created NFT.
     * @param uri The URI associated with the newly created NFT.
    */
    event NftCreated(
        address indexed owner,
        uint256 indexed tokenId,
        string uri
    );


    /**
     * @dev Emitted when the listing of an NFT is updated.
     * @param tokenId The unique identifier of the updated NFT listing.
     * @param caller The address of the caller who updated the NFT listing.
     * @param newPrice The new price at which the NFT is listed for sale.
    */
    event NftListingUpdated(
        uint256 indexed tokenId,
        address indexed caller,
        uint256 newPrice
    );

    /**
     * @dev Emitted when an NFT is successfully bought.
     * @param tokenId The unique identifier of the purchased NFT.
     * @param seller The address of the seller from whom the NFT was bought.
     * @param buyer The address of the buyer who successfully bought the NFT.
     * @param price The price at which the NFT was bought.
    */
    event NftBought(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    /**
     * @dev Modifier to check if an NFT is listed for sale.
     * @param tokenId The unique identifier of the NFT to check.
     * @return bool True if the NFT is listed, otherwise false.
     * @notice Not listed if the NFT is not currently listed for sale.
    */
    modifier isListed(uint256 tokenId) {
        require(_activeItem[tokenId].price > 0, "Not listed");
        _;
    }

    
    /**
     * @dev Modifier to check if the caller is the owner of a specific NFT.
     * @param tokenId The unique identifier of the NFT to check ownership.
     * @param spender The address of the caller to check against ownership.
     * @return bool True if the caller is the owner, otherwise false.
     * @notice You are not the owner if the caller is not the owner of the NFT.
    */
    modifier isOwner(uint256 tokenId, address spender) {
        require(spender == ownerOf(tokenId), "You are not the owner");
        _;
    }


    /**
    * @dev Creates a new NFT and assigns it to the specified address with the given URI.
    *
    * Requirements:
    * - The target address must not be the zero address.
    * - Minting to the contract address is not allowed.
    * - The URI must not be empty.
    *
    * @param to The address to which the new NFT is assigned.
    * @param uri The URI associated with the new NFT.
    */    
    function createNft(address to, string calldata uri) public {
        require(to != address(0), "Address zero is not a valid minter address");
        require(to != address(this), "Minting to the contract address is not allowed");
        require(bytes(uri).length > 0, "URI cannot be empty");
        uint256 tokenId = _tokenIdCounter.current();
        _safeMintAndSetTokenURI(to, tokenId, uri);
        _tokenIdCounter.increment();
        emit NftCreated(to, tokenId, uri);
    }

    /**
    * @dev Internal function to safely mint a new NFT and set its URI.
    *
    * This function combines the _safeMint and _setTokenURI operations.
    *
    * @param to The address to which the new NFT is assigned.
    * @param tokenId The unique identifier of the new NFT.
    * @param uri The URI associated with the new NFT.
    */
    function _safeMintAndSetTokenURI(address to, uint256 tokenId, string calldata uri) internal {
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
    }

    /**
    * @dev Lists an existing NFT for sale at the specified price.
    *
    * Requirements:
    * - The caller must be the owner of the NFT.
    * - The NFT must exist.
    * - The NFT must not be already listed for sale.
    * - The specified price must be greater than zero.
    *
    * After listing, the NFT information, including the seller's address and price, is stored.
    *
    * @param tokenId The unique identifier of the NFT to be listed.
    * @param price The price at which the NFT is listed for sale.
    */ 
    function listNft(
        uint256 tokenId,
        uint256 price
    ) public isOwner(tokenId, msg.sender) {
        require(_exists(tokenId), "NFT does not exist");
        require(_activeItem[tokenId].price == 0, "Already listed");
        require(price > 0, "Price must be greater than zero");
        string memory _url = tokenURI(tokenId);
        _activeItem[tokenId] = ListedNFT(msg.sender, price, _url); // push item into the array that store listedItem

        emit NftListed(tokenId, msg.sender, price);
    }

    /**
    * @dev Cancels the listing of an NFT, marking it as unlisted.
    *
    * Requirements:
    * - The caller must be the owner of the listed NFT.
    * - The NFT must be currently listed for sale.
    *
    * This function marks the NFT as unlisted by setting its price to zero.
    *
    * @param tokenId The unique identifier of the NFT to cancel the listing for.
    */
    function cancelListing(
        uint256 tokenId
    ) public isListed(tokenId) isOwner(tokenId, msg.sender) {
        // in front-end, we can check because _activeItem[tokenId].seller is "0x000000000000000000000000000000000000000"
        _activeItem[tokenId].price = 0; // or any other way to mark it as unlisted
        event NftListingCancelled(uint256 indexed tokenId, address indexed owner);
    }

    /**
    * @dev Updates the listing of an NFT with a new sale price.
    *
    * Requirements:
    * - The caller must be the owner of the listed NFT.
    * - The NFT must be currently listed for sale.
    * - The new price must be greater than zero.
    *
    * This function updates the sale price of the NFT.
    *
    * @param tokenId The unique identifier of the NFT to update the listing for.
    * @param newPrice The new sale price at which the NFT is listed.
    */
    function updateListing(
        uint256 tokenId,
        uint256 newPrice
    ) public isListed(tokenId) isOwner(tokenId, msg.sender) {
        require(newPrice > 0, "Invalid new price");
        _activeItem[tokenId].price = newPrice;

        event NftListingUpdated(uint256 indexed tokenId, address indexed owner, uint256 newPrice);
    }

    /**
    * @dev Allows a user to purchase a listed NFT.
    *
    * Requirements:
    * - The NFT must be listed for sale.
    * - The buyer cannot be the seller.
    * - The correct payment amount must be sent.
    *
    * Upon a successful purchase, the NFT is transferred to the buyer, and the seller's listing is removed.
    *
    * @param tokenId The unique identifier of the NFT to be purchased.
    */
    function buyNft(uint256 tokenId) public payable isListed(tokenId) {
        ListedNFT storage currentNft = _activeItem[tokenId];
        require(msg.sender != currentNft.seller, "Can Not buy your own NFT");
        require(msg.value == currentNft.price, "Incorrect payment amount");
        address seller = currentNft.seller;
        delete _activeItem[tokenId]; // when buy successfully, the new owner need to list again that it could be in the marketplace
        _transfer(seller, msg.sender, tokenId);

        // Send the correct amount of wei to the seller
        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "Payment failed");

        event NftBought(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    }

    /**
    * @dev Hook called before any token transfer to enforce additional transfer logic.
    *
    * This function ensures that the specified `batchSize` is considered during the token transfer.
    * It overrides the same function in both ERC721 and ERC721Enumerable.
    *
    * @param from The address from which the token is being transferred.
    * @param to The address to which the token is being transferred.
    * @param tokenId The unique identifier of the token being transferred.
    * @param batchSize The number of tokens being transferred as a batch.
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
    * @dev Internal function to burn (destroy) a token.
    *
    * This function overrides the same function in both ERC721 and ERC721URIStorage.
    *
    * @param tokenId The unique identifier of the token to be burned.
    */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }


    /**
    * @dev Retrieves the URI of a specific token.
    *
    * This function overrides the same function in both ERC721 and ERC721URIStorage.
    *
    * @param tokenId The unique identifier of the token for which to retrieve the URI.
    * @notice The URI associated with the specified token.
    */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
    * @dev Checks if a contract implements a specific interface.
    *
    * This function overrides the same function in both ERC721 and ERC721Enumerable.
    *
    * @param interfaceId The interface identifier to check for support.
    * @notice True if the contract supports the specified interface, otherwise false.
    */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @dev Retrieves information about the listing status of a specific NFT.
    *
    * @param tokenId The unique identifier of the NFT for which to retrieve listing information.
    * @notice A memory struct containing details about the NFT's listing status.
    */
    function getActiveItem(
        uint256 tokenId
    ) public view returns (ListedNFT memory) {
        return _activeItem[tokenId];
    }

    /**
    * @dev Transfers ownership of a specified NFT from one address to another.
    *
    * This function overrides the same function in ERC721 to ensure that listed NFTs cannot be transferred.
    *
    * Requirements:
    * - The NFT must not be listed for sale.
    *
    * @param from The current owner of the NFT.
    * @param to The address to which the ownership of the NFT is transferred.
    * @param tokenId The unique identifier of the NFT to be transferred.
    */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override( ERC721) {
        require(_activeItem[tokenId].price == 0, "You can't transfer a listed NFT");
        super.transferFrom(from, to, tokenId);
    }

    /**
    * @dev Safely transfers ownership of a specified NFT from one address to another.
    *
    * This function overrides the same function in ERC721 to ensure that listed NFTs cannot be transferred.
    *
    * Requirements:
    * - The NFT must not be listed for sale.
    *
    * @param from The current owner of the NFT.
    * @param to The address to which the ownership of the NFT is transferred.
    * @param tokenId The unique identifier of the NFT to be transferred.
    * @param data Additional data with no specified format to be included in the call.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721) {
        require(_activeItem[tokenId].price == 0, "You can't transfer a listed NFT");
        _safeTransfer(from, to, tokenId, data);
    }
}
