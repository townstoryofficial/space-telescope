// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IInventory {
    function gameMintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

contract Telescope is Ownable, Pausable, AccessControl, ReentrancyGuard {
    uint256 public saleStartTime;
    uint256 public keepTime;
    uint256 public mintMax;
    uint256 public salePrice;
    uint256 public telescopeId;
    address public inventory;

    mapping(address => uint256) public amountMinted;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        uint256 _saleStartTime,
        address _inventory,
        address _minter
    ) {
        saleStartTime = _saleStartTime;
        telescopeId = 111;
        keepTime = 2 weeks;
        mintMax = 2;
        salePrice = 1 ether;
        inventory = _inventory;
        _grantRole(MINTER_ROLE, _minter);
    }

    modifier _notContract() {
        uint256 size;
        address addr = _msgSender();
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "Contract is not allowed");
        require(_msgSender() == tx.origin, "Proxy contract is not allowed");
        _;
    }

    modifier _saleBetweenPeriod(uint256 _startTime, uint256 _endTime) {
        require(currentTime() >= _startTime, "Sale has not started yet");
        require(currentTime() < _endTime, "Sale is finished");
        _;
    }

    function mint(uint256 amount) 
        public 
        payable
        whenNotPaused
        _notContract
        _saleBetweenPeriod(saleStartTime, saleStartTime + keepTime)
        nonReentrant
    {
        require(amountMinted[msg.sender] + amount <= mintMax, "Minted reached the limit");

        uint256 totalValue = salePrice * amount;
        require(msg.value >= totalValue, "Not enough funds");

        amountMinted[msg.sender] += amount;
        _gameMint(msg.sender, telescopeId, amount);
    }

    function reward(address[] memory addrs, uint256 amount) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < addrs.length; i++) {
            _gameMint(addrs[i], telescopeId, amount);
        }
    }

    function _gameMint(address to, uint256 id, uint256 amount) internal {
        uint256[] memory _ids = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);

        _ids[0] = id;
        _amounts[0] = amount;
        IInventory(inventory).gameMintBatch(to, _ids, _amounts, "");
    }

    function currentTime() private view returns (uint256) {
        return block.timestamp;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSaleStartTime(uint256 _saleStartTime) public onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setKeepTime(uint256 _keepTime) public onlyOwner {
        keepTime = _keepTime;
    }

    function setMintMax(uint256 _mintMax) public onlyOwner {
        mintMax = _mintMax;
    }

    function setSalePrice(uint256 _salePrice) public onlyOwner {
        salePrice = _salePrice;
    }

    function setInventory(address _inventory) public onlyOwner {
        inventory = _inventory;
    }

    function setTelescopeId(uint256 _telescopeId) public onlyOwner {
        telescopeId = _telescopeId;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}