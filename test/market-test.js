const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarket", function () {
  it("Should create and execute market sales", async function () {
    
    const NFTMarket = await ethers.getContractFactory("NFTMarket");
    const market =  await NFTMarket.deploy();
    await market.deployed();
    const marketAddress = market.address;

    const NFT = await ethers.getContractFactory("NFT");
    const nftContract = await NFT.deploy(marketAddress);
    await nftContract.deployed();
    const nftContractAddress = nftContract.address;

    let listingPrice = await market.getListingPrice();
    //listingPrice = listingPrice.toString();
    //listingPrice = ethers.utils.parseUnits(listingPrice, 'wei');
    console.log(listingPrice);

    const auctionPrice = ethers.utils.parseEther("1");
    console.log(auctionPrice);

    //mint two nfts
    const tokenId_1 = await nftContract.createToken("https://myNFTUri1.com");
    const tokenId_2 = await nftContract.createToken("https://myNFTUri2.com");

    //create market items
    console.log("********** Creating market item... **********");
    await market.creatMarketItem(nftContractAddress, 1, auctionPrice, { value: listingPrice });
    await market.creatMarketItem(nftContractAddress, 2, auctionPrice, { value: listingPrice });
    console.log("********** Market item created... **********");

    const accounts = await ethers.getSigners();

    const [_, buyerAddress] = await ethers.getSigners();

    console.log("********** Selling an item... **********");
    await market.connect(buyerAddress).createMarketSale(nftContractAddress, 1, { value:auctionPrice });
    console.log("********** Item sold **********");

    let items = await market.fetchUnsoldMarketItems();

    items = await Promise.all(items.map( async x => {
      const tokenUri = await nftContract.tokenURI(x.tokenId);
      let item = {
        price: x.price.toString(),
        tokenId: x.tokenId.toString(),
        seller: x.seller,
        owner: x.owner,
        tokenUri
      }
      return item;
    }));

    console.log('items:', items);
  });
});
