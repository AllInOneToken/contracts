// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AllInOnePoolStorageInterface {
    function depositTokens(uint _amount) external;
    function withdraw(address to, uint amount) external;
    function getSmartContractBalance() external view returns(uint);
}
