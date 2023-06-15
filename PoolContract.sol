// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AllInOnePoolStorage {
    IERC20 _token;
    
    constructor(address token) {
        _token = IERC20(token);
    }

    // Modifier to check token allowance
    modifier checkAllowance(uint amount) {
        require(_token.allowance(msg.sender, address(this)) >= amount, "Error");
        _;
    }

    // Account A must to call this function and then deposit an amount of tokens 
    function depositTokens(uint _amount) external checkAllowance(_amount) {
        _token.transferFrom(msg.sender, address(this), _amount);
    }

    // to = Account B's address
    function withdraw(address to, uint amount) external {
        _token.transfer(to, amount);
    }

    // Allow you to show how many tokens owns this smart contract
    function getSmartContractBalance() external view returns(uint) {
        return _token.balanceOf(address(this));
    }
    
}
