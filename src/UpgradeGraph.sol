// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GraphProtocolUpgrade is Initializable, OwnableUpgradeable, ERC721Upgradeable, ERC721URIStorageUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    address public tokenAddress;
    mapping(uint256 => bool) public listedNFT;
    mapping(uint256 => uint256) public priceofNFT;

    event NFTListed(address indexed seller, uint256 indexed tokenId, uint256 price, string tokenUri);
    event NFTBought(address indexed seller, address indexed buyer, uint256 indexed tokenId, string tokenUri, uint256 price);
    event NFTCreated(address indexed creator, string tokenUri, uint256 tokenId);
    event NFTTransferred(address indexed creator, address indexed receiver, string tokenUri, uint256 tokenId);
    event NFTUnlisted(address indexed seller, uint256 indexed tokenId, string tokenUri);

    function initialize(address usdcAddress) public initializer {
        __Ownable_init();
        __ERC721_init("GraphProtocol", "GRT");
        tokenAddress = usdcAddress;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        require(to != address(0), "Cannot mint to zero Address");
        require(bytes(uri).length != 0, "Cannot set an empty URI");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, uri);
        emit NFTCreated(to, uri, newTokenId);
    }

    function listNft(uint256 tokenId, uint256 price) public onlyOwner {
        require(price > 0, "Price cannot be set to zero");
        listedNFT[tokenId] = true;
        priceofNFT[tokenId] = price;
        approve(address(this), tokenId);
        emit NFTListed(ownerOf(tokenId), tokenId, price, tokenURI(tokenId));
    }

    function buy(uint256 tokenId, uint256 _amount) public {
        require(listedNFT[tokenId], "NFT is not listed for sale");
        require(msg.sender != ownerOf(tokenId), "You cannot buy your own Token");
        require(_amount == priceofNFT[tokenId], "You don't have enough Tokens to buy it");
        address seller = ownerOf(tokenId);
        address buyer = msg.sender;
        // Ensure the contract is allowed to spend the buyer's tokens
        IERC20Upgradeable tokenContract = IERC20Upgradeable(tokenAddress);
        uint256 allowance = tokenContract.allowance(buyer, address(this));
        require(allowance >= _amount, "You must approve the contract to spend your tokens");
        // Transfer tokens from the buyer to the seller
        require(tokenContract.transferFrom(buyer, seller, _amount), "Token transfer failed");
        // Transfer the NFT to the buyer
        ERC721Upgradeable(address(this)).safeTransferFrom(seller, buyer, tokenId);

        listedNFT[tokenId] = false;
        emit NFTBought(seller, buyer, tokenId, tokenURI(tokenId), priceofNFT[tokenId]);
        priceofNFT[tokenId] = 0;
    }

    function removeListing(uint256 tokenId) external onlyOwner {
        listedNFT[tokenId] = false;
        approve(address(0), tokenId);
        priceofNFT[tokenId] = 0;
        emit NFTUnlisted(ownerOf(tokenId), tokenId, tokenURI(tokenId));
    }

    function transfer(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
        emit NFTTransferred(from, to, tokenURI(tokenId), tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable,ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
   
}
