//SPDX-License-Identifier: UNLICENSED
/* Needed functionalites:
    - List, Unlist, Sale
    - Whitelist for KYC
    - Split payments so we can take a slice
    - Need to have "whole" tokens where they are not divisible by infinity
    - Fungible, all tokens are equal
    - Customizable in constructor where we can add information as needed to display
    - create a cap so no more tokens can be minted

  Other considerations:
    - no need to know who owns what tokens if the smart contract keeps them from not selling outside of env
    - best way to handle listings
    - want to create it to be "pausable"
    - KYC information will be held "off-chain"
    - openzeppelin considerations:
        - multicall
        - escrow
        - escrow refund
        - PaymentSplitter
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract RealiumToken is ERC1155, Ownable, AccessControl {
    // Creat Roles(Users who have access)
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

    struct Listing {
        address tokenSeller;
        uint256 numTokens;
        uint256 price;
    }

    struct Property {
        string parcelNumber;
        bool listed;
        uint256 numTokens;
        uint256 price;
        address owner;
    }

    mapping (address => uint256) public listingNums;

    event Listed(address indexed owner, uint256 price, uint256 numTokens);
    event Unlisted(address indexed owner, uint256 previousPrice, uint256 numTokens);
    event Sale(address indexed seller, address indexed buyer, uint256 price, uint256 numTokens);

    address [] public addresses;
    Listing [] public allListings;

    string private TOKEN_NAME;
    string private TOKEN_SYMBOL;
    string private parcelNumber;

    constructor(uint256 initialSupply, string memory parcelNum) ERC20("Realium Property 1", "RLM") {
        _mint(msg.sender, initialSupply);
        parcelNumber = parcelNum;
        allListings.push(Listing(msg.sender,0,0));
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
    
    function getListings() public view returns (Listing[] memory){
        return allListings;
    }
    
    function getParcelNumber() public view returns (string memory){
        return parcelNumber;
    }

    function addUser(address newUser) public onlyOwner{
        _setupRole(USER_ROLE, newUser);
    }

   function listProperty(uint256 _price, uint256 _numTokens) public onlyRole(USER_ROLE) {
        require(_price > 0, "Price must be set above 0.");
        require(_numTokens > 0, "Number of tokens must be set above 0.");
        unlistProperty();
        allListings.push(Listing(msg.sender,_numTokens, _price));
        listingNums[msg.sender] = allListings.length-1;
        emit Listed(msg.sender, _price, _numTokens);
    }
    
    function unlistProperty() public onlyRole(USER_ROLE) {
        //need to check that owner has tokens
        uint256 listingNum = listingNums[msg.sender];
        if (listingNum != 0) {
            Listing memory listing = allListings[listingNum];
            allListings[listingNum] = Listing(msg.sender,0,0);
            listingNums[msg.sender] = 0; 
            emit Unlisted(msg.sender, listing.price, listing.numTokens);
        }
    }

    // Function that allows you to convert an address into a payable address
    function _make_payable(address x) internal pure returns (address payable) {
        return payable(x);
    }

    function sendTo(address _payee, uint256 _amount) public {
        require(_payee != address(0) && _payee != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        address payable payeeAddress = _make_payable(_payee);
        payeeAddress.transfer(_amount);
    }


    // Need to send msg.value to the recipient here so ETH is being traded for tokens
    // function buyPropertyToken(address _sellerAddress, uint256 amount) public payable onlyRole(USER_ROLE) {
    //     uint256 numListing = listingNums[_sellerAddress];
    //     Listing memory listing = allListings[numListing];
    //     require(msg.sender != address(0) && msg.sender != address(this));
    //     require(listing.price > 0, "The property must be sold for more than 0");
    //     uint256 total = listing.price*listing.numTokens;
    //     require(msg.value >= total, "Value must be greater than the price of all the tokens");
    //     //TODO: FIGURE OUT HOW TO SEND ETH FOR ERC-20
    //     // address payable ownerAddressPayable = _make_payable(_sellerAddress); // We need to make this conversion to be able to use transfer() function to transfer ethers
    //     approve(_sellerAddress, total);
    //     transferFrom(_sellerAddress, msg.sender, listing.numTokens); // We can't use _addTokenTo or_removeTokenFrom functions, now we have to use transferFrom
    //     address payable payerAddress = _make_payable(msg.sender);
    //     payerAddress.transfer(amount);
    //     // sendTo(ownerAddressPayable, total);
    //     allListings[numListing]=Listing(msg.sender,0,0);
    //     emit Sale(_sellerAddress, msg.sender, listing.price, listing.numTokens);
    // }   
}