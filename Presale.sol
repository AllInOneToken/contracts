// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AIO.sol";
import "./PoolContract.sol";
import "./SafeMath.sol";

contract AIOTokenPresale {
    AIO public token;
    AllInOnePoolStorage public poolContract;
    using SafeMath for uint256;

    address payable public wallet;
    uint256 public constant TOKEN_PRICE = 9900;
    uint256 public presaleEndTime = 90 days;

    event TokensPurchased(address buyer, uint256 amount, uint256 price);

    constructor(
        address _token,
        address payable _wallet,
        address _poolContract
    ) {
        token = AIO(_token);
        wallet = _wallet;
        poolContract = AllInOnePoolStorage(_poolContract);
    }

    receive() external payable {
        purchaseTokens();
    }

    function purchaseTokens() public payable {
        require(block.timestamp > presaleEndTime, "Presale has ended");
        require(msg.value > 0, "Payment must be greater than 0");
        require(msg.value > 100 ether, "Sent MATIC Should be atleast 100.");

        uint256 amount = msg.value * TOKEN_PRICE;
        require(amount > 0, "Insufficient amount");
        require(amount <= token.balanceOf(address(poolContract)), "Insufficient balance");
        poolContract.withdraw(msg.sender, amount);
        token.addPresoldAddress(msg.sender, amount);
        wallet.transfer(msg.value);
        emit TokensPurchased(msg.sender, amount, TOKEN_PRICE);
    }
}
