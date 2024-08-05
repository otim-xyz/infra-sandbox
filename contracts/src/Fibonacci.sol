// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Fibonacci {
    event NumberF0Set(uint256 f0, uint256 newF0);
    event NumberF1Set(uint256 f1, uint256 newF1);

    error F0NotEqualToF1(uint256 f0, uint256 newF0, uint256 f1);
    error F1NotFibonacci(uint256 f0, uint256 f1, uint256 newF1);

    uint256 private f0 = 0;
    uint256 private f1 = 1;

    function setF0F1(uint256 newF0, uint256 newF1) public {
        if (newF0 != f1) {
            revert F0NotEqualToF1(f0, newF0, f1);
        }
        if (newF1 != f0 + f1) {
            revert F1NotFibonacci(f0, f1, newF1);
        }
        emit NumberF0Set(f0, newF0);
        f0 = newF0;

        emit NumberF1Set(f1, newF1);
        f1 = newF1;
    }

    function getCurrentValues() public view returns (uint256, uint256) {
        return (f0, f1);
    }
}
