// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, AccessControl {
    // contract inherits from ERC721, ERC721Enumerable, ERC721URIStorage and Ownable contracts
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721("MyNFT", "MNFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    struct ListedNFT {
        // struct to store NFT details for sale
        address seller; // seller address
        uint256 price; // sale price
        string url; // NFT URI
    }

    mapping(uint256 => ListedNFT) private _activeItem; // map NFT tokenId to ListedNFT struct, _activeItem store array of item listed into marketplace

    Counters.Counter private _tokenIdCounter; // counter to generate unique token ids

    constructor() ERC721("MyNFT", "MNFT") {} // constructor to initialize the contract with name "MyNFT" and symbol "MNFT"

    // event emitted when an NFT listing is cancelled
    event NftListingCancelled(uint256 indexed tokenId, address indexed caller); 
    // event emitted when an NFT is listed for sale
    event NftListed(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    ); 
    // event emitted when an NFT listing is updated
    event NftListingUpdated(
        uint256 indexed tokenId,
        address indexed caller,
        uint256 newPrice
    ); 
    // event emitted when an NFT is bought
    event NftBought(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    ); 

    // modifier to check if an NFT is not listed for sale
    modifier notListed(uint256 tokenId) {
        require(_activeItem[tokenId].price == 0, "Already listed");
        _;
    }

    // modifier to check if an NFT is listed for sale
    modifier isListed(uint256 tokenId) {
        require(_activeItem[tokenId].price > 0, "Not listed");
        _;
    }
    // modifier to check if the caller is the owner of the NFT
    modifier isOwner(uint256 tokenId, address spender) {
        require(spender == ownerOf(tokenId), "You are not the owner");
        _;
    }

    // Function to create a new NFT with access control and flexible URI handling
    function createNft(address to, string calldata uri) public onlyRole(MINTER_ROLE) {
        require(to != address(0), "Address zero is not a valid minter address");
        require(bytes(uri).length > 0, "Empty URI");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        // Emitting event for tracking
        emit Transfer(address(0), to, tokenId);
    }

    //function to list NFT into the marketplace 
    function listNft(
        uint256 tokenId,
        uint256 price
    ) public notListed(tokenId) isOwner(tokenId, msg.sender) {
        require(price > 0, "Invalid price");
        string memory _url = tokenURI(tokenId);
        _activeItem[tokenId] = ListedNFT(msg.sender, price, _url); // push item into the array that store listedItem

        emit NftListed(tokenId, msg.sender, price);
    }

    //function to delete item in the mapping
    function cancelListing(
        uint256 tokenId
    ) public isListed(tokenId) isOwner(tokenId, msg.sender) {
        // in front-end, we can check because _activeItem[tokenId].seller is "0x000000000000000000000000000000000000000"
        delete _activeItem[tokenId];

        emit NftListingCancelled(tokenId, msg.sender);
    }

    // Function to update the price of a listed NFT with validation
function updateListing(uint256 tokenId, uint256 newPrice) public isListed(tokenId) isOwner(tokenId, msg.sender) {
    require(newPrice > 0, "Invalid new price");
    
    // Ensure that the new price is different from the existing price
    require(_activeItem[tokenId].price != newPrice, "New price must be different");

    _activeItem[tokenId].price = newPrice;

    emit NftListingUpdated(tokenId, msg.sender, newPrice);
}
    }

// Function to allow a user to buy a listed NFT with reentrancy guard and value check
function buyNft(uint256 tokenId) public payable isListed(tokenId) nonReentrant {
    ListedNFT storage currentNft = _activeItem[tokenId];

    // Ensure the buyer is not the seller
    require(msg.sender != currentNft.seller, "Cannot buy your own NFT");

    // Ensure the sent value is equal to the listed price
    require(msg.value == currentNft.price, "Incorrect payment amount");

    // Transfer ownership of the NFT to the buyer
    address seller = currentNft.seller;
    delete _activeItem[tokenId];
    _transfer(seller, msg.sender, tokenId);

    // Send the correct amount of wei to the seller
    (bool success, ) = payable(seller).call{value: msg.value}("");
    require(success, "Payment failed");

    emit NftBought(tokenId, seller, msg.sender, msg.value);
}


    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }


    // function go get URI of created NFT
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

// Function to get information about a listed NFT based on its token ID with existence check
function getActiveItem(uint256 tokenId) public view returns (ListedNFT memory) {
    require(_exists(tokenId), "Token ID does not exist");
    return _activeItem[tokenId];
}

        /**
     * @dev See {IERC721-transferFrom}.
     * Changes is made to transferFrom to prevent transfers of a listed NFT
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
     * @dev See {IERC721-safeTransferFrom}.
     * Changes is made to safeTransferFrom to prevent transfers of a listed NFT
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
