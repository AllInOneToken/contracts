// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./PoolContract.sol";
import "./Presale.sol";
import "./Staking.sol";

contract AIO is ERC20 {
    uint256 private TOTAL_SUPPLY = 99_999_999_999 * 10 ** decimals();

    uint256 private _totalStaked;
    mapping(address => bool) public _transferLocked;
    address public _owner;
    AllInOnePoolStorage public poolStorage;
    AllInOneStaking public tokenStakingContract;

    uint256 public creationTime;
    uint256 public constant LOCK_PERIOD = 730 days;
    mapping(uint8 => uint256) STACKING_PERIOD;
    struct Partner {
        address _address;
        string  label;
        bool    exists;
    }

    mapping(address => Partner) public partners;

    struct Presale {
        address _user;
        uint    amount;
        uint256 presaleTime;
        bool    exists;
        uint    unlockedAmount;
    }

    mapping(address => Presale) public preSaledAddresses;

    uint public totalReleased = 0;
    uint lastReleaseTime;
    constructor() ERC20("All-In-One", "AIO") {
        _owner = msg.sender;
        
        _mint(address(this), TOTAL_SUPPLY);
        
        poolStorage = new AllInOnePoolStorage(address(this));
        tokenStakingContract = new AllInOneStaking(this, address(poolStorage));

        creationTime = block.timestamp;

        partners[msg.sender] = Partner(msg.sender, "owner", true);
        partners[address(poolStorage)] = Partner(address(poolStorage), "PoolStorage", true);
    }
    
    function approveAndCall(address spender, uint256 amount, bytes memory data) public returns (bool) {
        approve(spender, amount);
        (bool success, ) = spender.call(data);
        require(success, "Token: approveAndCall failed");
        return true;
    }
    
    function allowanceForPresaled(address spender, uint amount) public returns (bool) {
        if ( preSaledAddresses[spender].exists ) {
            uint unlockedAmount = calculateUnlockedAmount(preSaledAddresses[spender]);

            if ( unlockedAmount < amount ) {
                return false;
            }

            preSaledAddresses[spender].unlockedAmount += amount;
        }
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(allowanceForPresaled(msg.sender, amount), "You cant transfer with presaled token");

        return super.transfer(recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(allowanceForPresaled(msg.sender, amount), "You cant transfer with presaled token");
        return super.transferFrom(sender, recipient, amount);
    }

    function getPoolBalance() public view returns(uint){
        return poolStorage.getSmartContractBalance();
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Only owner allowed");
        _;
    }

    function addPartner(address _partner, string memory _label) onlyOwner public {
        partners[_partner] = Partner(_partner, _label, true);
    }

    modifier onlyPartners {
        require(partners[msg.sender].exists, "Only partners can call this function");
        _;
    }

    function addPresoldAddress(address _presoldwallet, uint amount) onlyPartners public {
        preSaledAddresses[_presoldwallet] = Presale(_presoldwallet, amount, block.timestamp, true, 0);
    }

    function releaseTokens() onlyOwner public {
        require( lastReleaseTime < 365 days, "Owner can release token once in a year");

        uint tokensToBeReleased = TOTAL_SUPPLY / 3;
        uint developersAmount =  tokensToBeReleased * 10 / 100; // Developers, Marketing, Ecosystem
        uint poolStorageAmount = tokensToBeReleased * 32 / 100; // PoolStorage(Staking rewards, Presale, Airdrops)
        uint foundationAmount = tokensToBeReleased * 30 / 100; // PoolStorage(Staking rewards, Presale, Airdrops)
        uint marketingAmount = tokensToBeReleased * 8 / 100; // PoolStorage(Staking rewards, Presale, Airdrops)
        uint foundersAmount = tokensToBeReleased * 3 / 100;  // Owner
        uint ecosystemAmount = tokensToBeReleased * 17 / 100;

        _transfer(address(this), address(poolStorage), poolStorageAmount); // PoolStorage (Staking rewards, Presale, Airdrops) (32%)
        _transfer(address(this), 0x98B4838A59b47850fff72299A21a0b41ed55F2B2, foundationAmount); // Foundation share (30%)
        _transfer(address(this), 0xDB40be1316FE88d8e8E9F28c4a42f1baE9fdEFb1, marketingAmount); // Marketing share (8%)
        _transfer(address(this), 0x07464b18f2F90F1a85586b6369EfEf21da290916, ecosystemAmount); // Ecosystem share (17%)
        _transfer(address(this), 0xF8A2B83bd7C3DD241C83E7e2EEFe9a8C536dC66B, developersAmount); // Developer share (10%)
        _transfer(address(this), 0xFB2688E5b2a4766352f2E0Bc24217Ef2f04751d5, foundersAmount); // Owner (3%)

        totalReleased = developersAmount + poolStorageAmount + foundationAmount + marketingAmount + foundersAmount + ecosystemAmount;
        lastReleaseTime = block.timestamp;
    }

    function calculateUnlockedAmount(Presale storage preSale) internal view returns (uint) {
        if (block.timestamp < preSale.presaleTime + 365 days) {
            return 0;  // No tokens unlocked before the lock period ends
        } else {
            uint elapsedMonths = (block.timestamp - preSale.presaleTime + 365 days) / (30 days);  // Assuming 30 days per month
            elapsedMonths = elapsedMonths - 23;
            uint unlockedAmount = 0;
            
            for (uint256 month = 1; month <= elapsedMonths; month++) {
                unlockedAmount += preSale.amount * 10 / 100;
            }

            if (unlockedAmount > preSale.amount) {
                return preSale.amount;
            }

            return unlockedAmount - preSale.unlockedAmount;
        }
    }
}
