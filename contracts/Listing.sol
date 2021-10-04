// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

contract Listing is AccessControlUpgradeable, ERC1155Upgradeable{
    bytes32 public constant ALLOWED_USER_ROLE = keccak256("USER_ROLE");

    struct Listing {
        address seller;
        uint256 numTokens;
        uint256 price;
        bool listed;
        bool isListing;
        uint256 index;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    string error_message = "Listing does not exist for this address.";

    // EVENTS
    event Listed(address indexed owner, uint256 price, uint256 numTokens);
    event Unlisted(address indexed owner, uint256 previousPrice, uint256 numTokens);
    event Sale(address seller, address indexed buyer, uint256 price, uint256 numTokens);

    // PUBLIC VARIABLES
    mapping (address => Listing) private listings;
    address [] private listingIndexes;
    
    function isListing(address seller) public view returns(bool isIndeed){
        if (listingIndexes.length == 0) return false;
        return (listingIndexes[listings[seller].index]==seller);
    }

    function createListing(address seller, uint256 numTokens, uint256 price) public onlyRole(ALLOWED_USER_ROLE) returns (uint256 index){
        require(isListing(seller), "Listing for the address already exists. Please update current listing.");
        list(seller, price, numTokens);
        listingIndexes.push(seller);
        listings[seller].index = listingIndexes.length-1;
        emit Listed(msg.sender, price, numTokens);
        return listingIndexes.length-1;
    }

    function getListingByAddress(address seller) public view onlyRole(ALLOWED_USER_ROLE) returns(Listing memory listing) {
        require(!isListing(seller), error_message);
        return listings[seller];
    }

    //TODO: break this into a small bit size pieces where its update but really only changing price and numTokens, I don't think we will ever change index here
    function updateListing(address seller, uint256 numTokens, uint256 price, bool listed, uint256 index) onlyRole(ALLOWED_USER_ROLE) public returns (bool success){
        //Check there is currently a listings
        if (listed==false){
            unlist(seller);
        }
        else {
            list(seller, price, numTokens);
        }
        listings[seller].index=index;
        return true;
    }

    //May need to create a "admin" list that passes in address, and then have it always be msg.sender for security reasons
    // function list(address seller, uint256 price, uint256 numTokens) public onlyRole(ALLOWED_USER_ROLE) returns (bool success){
    //     require(!isListing(seller), error_message);
    //     listings[seller].seller=seller;
    //     listings[seller].numTokens=numTokens;
    //     listings[seller].price=price;
    //     listings[seller].listed=true;
    //     setApprovalForAll(address(this), true);
    //     emit Listed(seller, price, numTokens);
    //     return true;
    // }

    function list(address seller, uint256 price, uint256 numTokens) public onlyRole(ALLOWED_USER_ROLE) returns (bool success){
        emit Listed(seller, price, numTokens);
        return true;
    }

    //May need to create a "admin" unlist that passes in address, and then have it always be msg.sender for security reasons
    function unlist(address seller) public onlyRole(ALLOWED_USER_ROLE) returns (bool success){
        require(!isListing(seller), error_message);
        listings[seller].listed=false;
        setApprovalForAll(address(this), false);
        emit Unlisted(seller, listings[seller].price, listings[seller].numTokens);
        return true;
    }

    //This should be done after a SALE of the tokens only
    function removeListing(address seller) public onlyRole(ALLOWED_USER_ROLE) returns(uint256 index){
        require(!isListing(seller), "Listing does not exist. Cannot delete listing that does not exist.");
        uint256 rowToDelete = listings[seller].index;
        address keyToMove = listingIndexes[listingIndexes.length-1];
        listingIndexes[rowToDelete]=keyToMove;
        listings[keyToMove].index = rowToDelete;
        listingIndexes.pop();
        //emit event of unlist or deleted listing
        return rowToDelete;
    }

    function getListingCount() public view onlyRole(ALLOWED_USER_ROLE) returns (uint256){
        return listingIndexes.length;
    }

    function _make_payable(address x) internal pure returns (address payable) {
        return payable(x);
    }

    function sale(address seller, uint256 tokenId) public {
        transferToBuyer(seller, tokenId);
        sendEthToSeller(seller, listings[seller].numTokens*listings[seller].price);
        removeListing(seller);
        emit Sale(seller, msg.sender, listings[seller].price, listings[seller].numTokens);
    }

    // send ether from contract to seller
    function sendEthToSeller(address seller, uint256 totalPrice) public {
        address payable payeeAddress = _make_payable(seller);
        payeeAddress.transfer(totalPrice);
    }

    // Need to figure out how to add msg.value to a call. And I think the msg.value is automatically added to the 
    function transferToBuyer(address seller, uint256 tokenId) public payable onlyRole(ALLOWED_USER_ROLE){
        require(balanceOf(seller, tokenId)==listings[seller].numTokens);
        require(msg.value>=(listings[seller].price*listings[seller].numTokens));
        safeTransferFrom(seller, msg.sender, tokenId, listings[seller].numTokens, "");
    }
}