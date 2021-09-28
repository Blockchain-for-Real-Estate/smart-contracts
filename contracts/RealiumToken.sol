// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract RealiumToken is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ALLOWED_USER_ROLE = keccak256("USER_ROLE");

    //STRUCTS
    // TODO: Implement constructor to have property information
    // struct Property {
    //     string parcelNumber;
    //     bool listed;
    //     uint256 numTokens;
    //     uint256 price;
    //     address owner;
    // }

    struct Listing {
        address seller;
        uint256 numTokens;
        uint256 price;
        bool listed;
        bool isListing;
        uint256 index;
    }

    // EVENTS
    event Listed(address indexed owner, uint256 price, uint256 numTokens);
    event Unlisted(address indexed owner, uint256 previousPrice, uint256 numTokens);
    event Sale(address indexed seller, address indexed buyer, uint256 price, uint256 numTokens);

    // PUBLIC VARIABLES
    mapping (address => Listing) private listings;
    address [] private listingIndexes;
    string private TOKEN_NAME;
    string private TOKEN_SYMBOL;
    string private parcelNumber;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {

    }

    function initialize() initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(ALLOWED_USER_ROLE, msg.sender);
        addAllowedUserRole(msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
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

    // function addUserAddress(address userAddress) public{
    //     addAllowedUserRole(userAddress);
    // }
    
    // function getListings() public view returns (Listing[] memory){
    //     return listings;
    // }
    
    function getParcelNumber() public view returns (string memory){
        return parcelNumber;
    }

    function addAllowedUserRole(address newUser) public onlyRole(DEFAULT_ADMIN_ROLE){
        _setupRole(ALLOWED_USER_ROLE, newUser);
    }

    function revokeRole(bytes32 role, address account) public override {
        require(
            role != DEFAULT_ADMIN_ROLE,
            "ModifiedAccessControl: cannot revoke default admin role"
        );

        super.revokeRole(role, account);
    }

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
        require(!isListing(seller), "Listing does not exist for this address.");
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

    function list(address seller, uint256 price, uint256 numTokens) public onlyRole(ALLOWED_USER_ROLE) returns (bool success){
        require(!isListing(seller), "Listing does not exist for this address.");
        listings[seller].seller=seller;
        listings[seller].numTokens=numTokens;
        listings[seller].price=price;
        listings[seller].listed=true;
        emit Listed(seller, price, numTokens);
        return true;
    }

    function unlist(address seller) public onlyRole(ALLOWED_USER_ROLE) returns (bool success){
        require(!isListing(seller), "Listing does not exist for this address.");
        listings[seller].listed=false;
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

    // Function that allows you to convert an address into a payable address
    function _make_payable(address x) internal pure returns (address payable) {
        return payable(x);
    }

    // function sendTo(address _payee, uint256 _amount) public {
    //     require(_payee != address(0) && _payee != address(this));
    //     require(_amount > 0 && _amount <= address(this).balance);
    //     address payable payeeAddress = _make_payable(_payee);
    //     payeeAddress.transfer(_amount);
    // }


    // Need to send msg.value to the recipient here so ETH is being traded for tokens
    // function buyPropertyToken(address _sellerAddress, uint256 amount) public payable onlyRole(USER_ROLE) {
    //     uint256 numListing = listingNums[_sellerAddress];
    //     Listing memory listing = listings[numListing];
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
    //     listings[numListing]=Listing(msg.sender,0,0);
    //     emit Sale(_sellerAddress, msg.sender, listing.price, listing.numTokens);
    // }   
}