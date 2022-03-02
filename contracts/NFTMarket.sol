//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract NFTMarket is ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSold;

    address payable owner;
    uint256 listingPrice = 0.0025 ether;

    struct MarketItem {
        uint itemId;
        address nftAddress;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated (
        uint itemId,
        address nftAddress,
        uint256 tokenId,
        address indexed seller,
        address indexed owner,
        uint256 price,
        bool sold
    );

    mapping(uint256 => MarketItem) private marketItemsById;

    constructor(){
        owner = payable(msg.sender);
    }

    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    //Create a new item
    function creatMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {

        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price msut be equal to listing price");

        _itemIds.increment();
        uint256 newItemId = _itemIds.current();

       marketItemsById[newItemId] = MarketItem(
            newItemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated (
            newItemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    //Create market sale
    function createMarketSale(address nftContract, uint256 itemId) public payable nonReentrant{
        uint256 price = marketItemsById[itemId].price;
        uint256 tokenId = marketItemsById[itemId].tokenId;

        require(msg.value == price, "Please submit the asking price");

        //transfer the submitted price to the seller
        marketItemsById[itemId].seller.transfer(msg.value);

        //transfer the item to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        marketItemsById[itemId].owner = payable(msg.sender);
         marketItemsById[itemId].sold = true;
        _itemSold.increment();

        //transfer commission to contract's owener
        payable(owner).transfer(listingPrice);
    }

    //Unsold items
    function fetchUnsoldMarketItems() public view returns(MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemsCount = _itemIds.current() - _itemSold.current();

        MarketItem[] memory unsoldMarketItems = new MarketItem[](unsoldItemsCount);
        uint index = 0;

        for (uint i = 0; i < itemCount; i++) {
            if(marketItemsById[i + 1].owner == address(0)){
                uint currentItemId = marketItemsById[i + 1].itemId;
                MarketItem storage currentMarketItem = marketItemsById[currentItemId];
                unsoldMarketItems[index] = currentMarketItem;
                index++;
            }
        }

        return unsoldMarketItems;
    }

    //items created by sender
    function fetchMyNFTs() public view returns(MarketItem[] memory){
         uint totalItem = _itemIds.current();
         uint itemCount = 0;
         uint index = 0;

         for (uint i = 0; i < totalItem; i++) {
            if(marketItemsById[i + 1].owner == msg.sender){
                itemCount++;
            }
        }

        MarketItem[] memory myItems = new MarketItem[](itemCount);

        for (uint i = 0; i < totalItem; i++) {
            if(marketItemsById[i + 1].owner == msg.sender){
               uint currentItemId = marketItemsById[i + 1].itemId;
                MarketItem storage currentMarketItem = marketItemsById[currentItemId];
                myItems[index] = currentMarketItem;
                index++;
            }
        }

        return myItems;
    }

     //items created by seller
    function fetchNFTsCreatedBySeller() public view returns(MarketItem[] memory){
         uint totalItem = _itemIds.current();
         uint itemCount = 0;
         uint index = 0;

         for (uint i = 0; i < totalItem; i++) {
            if(marketItemsById[i + 1].seller == msg.sender){
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint i = 0; i < totalItem; i++) {
            if(marketItemsById[i + 1].seller == msg.sender){
               uint currentItemId = marketItemsById[i + 1].itemId;
                MarketItem storage currentMarketItem = marketItemsById[currentItemId];
                items[index] = currentMarketItem;
                index++;
            }
        }

        return items;
    }
}