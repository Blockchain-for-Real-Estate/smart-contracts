//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Property {

    event TokenListed(uint tokenId, uint32 listPrice);
    event TokenUnlisted(uint tokenId);
    event MakeOffer(uint offerId, uint32 offerPrice);
    event RetractOffer(uint offerId, uint32 offerPrice);
    event TokenTransfer(address from, address to, uint32 salePrice);

    struct Token {
        address currentOwner;
        uint32 originalTokenPrice;
        uint32 lastPurchasePrice;
        bool listed;
        uint32 listPrice;
    }

    struct Offer {
        address buyer;
        uint32 offerPrice;
        bool active;
    }

    string public propertyId;
    address private propertyOwner;
    uint public totalSupply;
    uint public circulatingSupply;
    Token[] private tokens;
    Offer[] private offers;
    mapping(address => uint) public addressToTokenCount;
    mapping(address => uint) public addressToOfferCount;
    uint public listingsCount;
    uint public offersCount;

    constructor(string memory _propertyId, address _propertyOwner, uint _totalSupply, uint _initialSupply, uint32 _pricePerShare ) {
        propertyId = _propertyId;
        totalSupply = _totalSupply;
        circulatingSupply = _initialSupply;
        propertyOwner = _propertyOwner;
        
        for(uint i = 1; i < _totalSupply; i++) {
            address _assignee;
            if (i < _initialSupply) {
                _assignee = _propertyOwner;
            } else {
                _assignee = msg.sender;
            }
            tokens.push(Token({
                currentOwner: _assignee,
                originalTokenPrice: _pricePerShare,
                lastPurchasePrice: _pricePerShare,
                listed: false,
                listPrice: 0
            }));
            addressToTokenCount[_assignee]++;
        }
    }

    modifier onlyAdmin() {
        _;
    }

    modifier onlyTokenOwner(uint _tokenId) {
        require(msg.sender == tokens[_tokenId].currentOwner);
        _;
    }

    modifier onlyOfferBuyer(uint _offerId) {
        require(msg.sender == offers[_offerId].buyer);
        _;
    }

    modifier isListed(uint _tokenId){
        require(tokens[_tokenId].listed==true);
        _;
    }

    function getListings() external view returns(Token[] memory) {
        // TODO get the listings that are active and return them
        // We may want to keep track of the number of listings, this will allow us to us a view function to see all listings
        Token[] memory listings = new Token[](listingsCount);
        uint256 count = 0;
        //TODO: is this the best check????
        if (count > listingsCount){
            return listings;
        }
        for (uint256 index = 0; index < tokens.length; index++) {
            if (tokens[index].listed == true){
                listings[count]=tokens[index];
                count++;
            }
        }

        return listings;
    }

    function getOffers() external view returns(Offer[] memory) {
        // TODO get the offers that are active and return them
        Offer[] memory activeOffers = new Offer[](offersCount);
        uint256 count = 0;
        if (count > offersCount){
            return activeOffers;
        }
        for (uint256 index = 0; index < tokens.length; index++) {
            if (offers[index].active == true){
                activeOffers[count]=offers[index];
                count++;
            }
        }
        return activeOffers;
    }

    function getAddressTokens() external view returns(Token[] memory) {
        // TODO get any tokens that are the senders
        Token[] memory addressTokens = new Token[](addressToTokenCount[msg.sender]);
        uint256 count = 0;
        for (uint256 index = 0; index < tokens.length; index++) {
            if (tokens[index].currentOwner == msg.sender){
                addressTokens[count]=tokens[index];
                count++;
            }
        }

        return addressTokens;
    }

    function getAddressOffers() external view returns(Offer[] memory) {
        // TODO get any offer that are the senders and are active
        Offer[] memory addressOffers = new Offer[](addressToOfferCount[msg.sender]);
        uint256 count = 0;
        for (uint256 index = 0; index < tokens.length; index++) {
            if (offers[index].buyer == msg.sender){
                addressOffers[count]=offers[index];
                count++;
            }
        }

        return addressOffers;
    }

    function getBalance(address addr) public view returns (uint) {
        return addressToTokenCount[addr];
    }

    function getToken(uint _tokenId) public view returns (Token memory) {
        return tokens[_tokenId];
    }

    function listToken(uint _tokenId, uint32 _listPrice) public onlyTokenOwner(_tokenId) {
        // TODO list the token
        tokens[_tokenId].listPrice = _listPrice;
        tokens[_tokenId].listed = true;
        listingsCount++;
    }

    function updateToken(uint _tokenId, uint32 _listPrice) public onlyTokenOwner(_tokenId) isListed(_tokenId) {
        tokens[_tokenId].listPrice = _listPrice;
    }

    function unlistToken(uint _tokenId) public onlyTokenOwner(_tokenId) isListed(_tokenId){
        tokens[_tokenId].listed = false;
        listingsCount--;
    }

    // TODO: check if the offerer has the amount to offer
    function makeOffer(uint32 _offerAmount) public {
        offers.push(Offer(msg.sender, _offerAmount, true));
        offersCount++;
        // TODO: make a mapping from address to uint and the uint is the _offerId, allow for easy updates but will allow only 1 offer to be made for 1 token.
        // TODO: transfer funds into smart contract
    }

    function updateOffer(uint _offerId, uint32 _offerPrice) public onlyOfferBuyer(_offerId) {
        offers[_offerId].offerPrice = _offerPrice;
        // TODO: adjust funds in smart contract
    }

    function retractOffer(uint _offerId) public onlyOfferBuyer(_offerId) {
        offers[_offerId].active = false;
        payable(msg.sender).transfer(offers[_offerId].offerPrice);
        offersCount--;
    }

    function buyListing(uint _tokenId) public payable {
        require(getBalance(tokens[_tokenId].currentOwner)>=1, "Seller does not have enough tokens.");
        require(msg.value >= tokens[_tokenId].listPrice, "Insufficient funds sent, please send the correct amount of funds.");
        // TODO: write the transferFrom transfers from smart contract to address of the tokens
        // transferFrom();
        payable(tokens[_tokenId].currentOwner).transfer(msg.value);
        tokens[_tokenId].listed=false;
        tokens[_tokenId].lastPurchasePrice=tokens[_tokenId].listPrice;
        //TODO: see if this incrementing works
        incrementTokenCount(msg.sender);
        decrementTokenCount(tokens[_tokenId].currentOwner);
        listingsCount--;
        emit TokenTransfer(tokens[_tokenId].currentOwner, msg.sender, tokens[_tokenId].listPrice);
    }


    //TODO: think through how this will work, because there is no listing so is it just any token that the owner holds that isnt listed?
    function acceptOffer(uint _offerId) public payable {
        require(getBalance(msg.sender)>=1, "Seller does not have enough tokens.");
        // TODO: write the transferFrom transfers from smart contract to address of the tokens
        // transferFrom();
        payable(offers[_offerId].buyer).transfer(msg.value);
        //TODO: see if this incrementing works
        incrementTokenCount(offers[_offerId].buyer);
        decrementTokenCount(msg.sender);
        offersCount--;
        emit TokenTransfer(msg.sender,offers[_offerId].buyer, offers[_offerId].offerPrice);
    }

    function releaseToken(uint _amount) public onlyAdmin {
        // TODO release the tokens to the propertyOwner
    }

    function incrementTokenCount(address tokenAddress) private {
        addressToTokenCount[tokenAddress] = addressToTokenCount[tokenAddress]+1;
    }

    function decrementTokenCount(address tokenAddress) private {
        addressToTokenCount[tokenAddress] = addressToTokenCount[tokenAddress]-1;
    }

    function transferFrom(address owner, address buyer, uint256 count) private {

    }
}