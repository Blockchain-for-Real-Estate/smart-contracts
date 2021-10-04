// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Listing.sol";


contract RealiumTokenV2 is Initializable, ERC1155Upgradeable, PausableUpgradeable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ALLOWED_USER_ROLE = keccak256("USER_ROLE");

    // EVENTS
    event Listed(address indexed owner, uint256 price, uint256 numTokens);
    event Unlisted(address indexed owner, uint256 previousPrice, uint256 numTokens);
    event Sale(address seller, address indexed buyer, uint256 price, uint256 numTokens);

    // PUBLIC VARIABLES
    // mapping (address => Listing) private listings;
    // address [] private listingIndexes;
    address public creator;

    //TODO: TAKE THIS OUT AND MAKE IT DYNAMIC
    //THESE ARE THE IDS FOR THE TOKENS
    uint256 public constant TESTPROPERTY1 = 0;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {

    }

    function initialize() initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ALLOWED_USER_ROLE, msg.sender);

        _mint(msg.sender, TESTPROPERTY1, 100, "");
        creator = msg.sender;
    }

    function setURI(string memory newuri) public onlyRole(ADMIN_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(ADMIN_ROLE)
    {
        _mint(account, id, amount, data);
    }

    // function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    //     public
    //     onlyRole(MINTER_ROLE)
    // {
    //     _mintBatch(to, ids, amounts, data);
    // }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function addAllowedUserRole(address newUser) public onlyRole(ADMIN_ROLE){
        _setupRole(ALLOWED_USER_ROLE, newUser);
    }

    // function revokeRole(bytes32 role, address account) public override {
    //     require(
    //         role != DEFAULT_ADMIN_ROLE,
    //         "ModifiedAccessControl: cannot revoke default admin role"
    //     );

    //     super.revokeRole(role, account);
    // }

    function list(address seller, uint256 price, uint256 numTokens, uint256 tokenId) public returns (bool success) {
        require(seller==msg.sender, "You must own the tokens to sell them.");
        require(balanceOf(seller, tokenId)>numTokens, "You must have sufficient tokens to sell.");
        emit Listed(seller, price, numTokens);
        return true;
    }

    function unlist(address seller, uint256 price, uint256 numTokens) public returns (bool success) {
        require(seller==msg.sender, "You must own the tokens to sell them.");
        emit Unlisted(seller, price, numTokens);
        return true;
    }

    function sale(address seller, uint256 tokenId, uint256 price, uint256 numTokens) public onlyRole(ALLOWED_USER_ROLE){
        require(price>0, "Price must be greater than 0");
        require(numTokens>0, "Number of tokens must be greater than 0.");
        transferToBuyer(seller, tokenId, price, numTokens);
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
    function transferToBuyer(address seller, uint256 tokenId, uint256 price, uint256 numTokens) public payable onlyRole(ALLOWED_USER_ROLE){
        require(balanceOf(seller, tokenId)==numTokens);
        require(msg.value>=(price*numTokens));
        safeTransferFrom(seller, msg.sender, tokenId, numTokens, "");
    }
}