// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";

uint256 constant initialSupply = 10;

contract RealiumERC20 is ERC20PresetMinterPauser {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ALLOWED_USER_ROLE = keccak256("USER_ROLE");

    string public metaDataUrl ="";

    constructor(string name, string symbol) ERC20("Realium Test", "REAL") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ALLOWED_USER_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8){
        return 0;
    }

    function setMetaDataUrl (string url) public{
        metaDataUrl = url;
    }

    function getMetaDataUrl() public view returns(string url){
        return metaDataUrl;
    }

    function addAllowedUserRole(address newUser) public onlyRole(ADMIN_ROLE){
        _setupRole(ALLOWED_USER_ROLE, newUser);
    }

    function list(address seller, uint256 price, uint256 numTokens) public returns (bool success) {
        require(seller==msg.sender, "You must own the tokens to sell them.");
        require(balanceOf(seller)>numTokens, "You must have sufficient tokens to sell.");
        emit Listed(seller, price, numTokens);
        return true;
    }

    function unlist(address seller, uint256 price, uint256 numTokens) public returns (bool success) {
        require(seller==msg.sender, "You must own the tokens to sell them.");
        emit Unlisted(seller, price, numTokens);
        return true;
    }

    function sale(address seller, uint256 price, uint256 numTokens) public onlyRole(ALLOWED_USER_ROLE){
        require(price>0, "Price must be greater than 0");
        require(numTokens>0, "Number of tokens must be greater than 0.");
        transferToBuyer(seller, price, numTokens);
        sendEthToSeller(seller, price*numTokens);
        emit Sale(seller, msg.sender, price, numTokens);
    }

    // send ether from contract to seller
    function sendEthToSeller(address seller, uint256 totalPrice) public {
        require(totalPrice>0, "Total price must be greater than 0.");
        require(seller!=msg.sender, "The buyer cannot be the sender.");
        address payable payeeAddress = payable(seller);
        payeeAddress.transfer(totalPrice);
    }

    // Need to figure out how to add msg.value to a call. And I think the msg.value is automatically added to the 
    function transferToBuyer(address seller, uint256 price, uint256 numTokens) public payable onlyRole(ALLOWED_USER_ROLE){
        require(balanceOf(seller)==numTokens);
        require(msg.value>=(price*numTokens));
        transferFrom(seller, msg.sender, numTokens);
    }
}