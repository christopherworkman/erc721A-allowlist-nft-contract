// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract ProjectName is
    Ownable,
    ReentrancyGuard,
    ERC721A
{
    uint256 public maxTokens = 10000; // total tokens that can be minted

    uint256 public PRICE = 0.02 ether;

    uint256 public maxMint = 20; // max that can be minted during pre or pub sale

    uint256 public amountForDevs = 100; // for marketing etc

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    // counters
    mapping(address => uint8) public _preSaleListCounter;
    mapping(address => uint8) public _pubSaleListCounter;

    // Contract Data
    string private _baseTokenURI;

    constructor() ERC721A("Project Name", "SYMBOL") {
    }

    // Sale Switches
    bool public preMintActive = false;
    bool public pubMintActive = false;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /* Sale Switches */
    function setPreMint(bool state) public onlyOwner {
        preMintActive = state;
    }

    function setPubMint(bool state) public onlyOwner {
        pubMintActive = state;
    }

    /* Allowlist Management */
    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = true;

            /**
            * @dev We don't want to reset _allowListClaimed count
            * if we try to add someone more than once.
            */
            _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
        }
    }

    function allowListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), "Zero address not on Allow List");

        return _allowListClaimed[owner];
    }

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _allowListClaimed numbers.
            _allowList[addresses[i]] = false;
        }
    }

    /* Setters */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxMint(uint256 quantity) external onlyOwner {
        maxMint = quantity;
    }

    function setMaxTokens(uint256 quantity) external onlyOwner {
        maxTokens = quantity;
    }

    /* Getters */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Minting */
    function preMint(uint8 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        // activation check
        require(preMintActive, "Pre minting is not active");
        require(_allowList[msg.sender], "You are not on the Allow List");
        require(totalSupply() + quantity <= maxTokens, "Not enough tokens left");
        require(
            _preSaleListCounter[msg.sender] + quantity <= maxMint,
            "Exceeds mint limit per wallet"
        );
        require(PRICE * quantity == msg.value, "Incorrect funds");

        // mint
        _safeMint(msg.sender, quantity);

        // increment counters
        _preSaleListCounter[msg.sender] = _preSaleListCounter[msg.sender] + quantity;
    }

    function publicMint(uint8 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        // activation check
        require(pubMintActive, "Public minting is not active");
        require(totalSupply() + quantity <= maxTokens, "Not enough tokens left");
        require(
            _pubSaleListCounter[msg.sender] + quantity <= maxMint,
            "Exceeds mint limit per wallet"
        );
        require(PRICE * quantity == msg.value, "Incorrect funds");

        // mint
        _safeMint(msg.sender, quantity);

        // increment counters
        _pubSaleListCounter[msg.sender] = _pubSaleListCounter[msg.sender] + quantity;
    }

    // for marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "too many already minted before dev mint"
        );
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
