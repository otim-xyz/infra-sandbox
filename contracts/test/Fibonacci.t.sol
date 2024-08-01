// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Fibonacci} from "../src/Fibonacci.sol";

contract FibonacciTest is Test {
    Fibonacci public fibonacci;

    function setUp() public {
        fibonacci = new Fibonacci();
    }

    function test_GoodSequence() public {
        uint256 nextValue = fibonacci.f0() + fibonacci.f1();
        fibonacci.setF0F1(fibonacci.f1(), nextValue);
        assertEq(fibonacci.getCurrentValue(), nextValue);
    }

    function test_BadF0() public {
        vm.expectRevert(abi.encodeWithSelector(Fibonacci.F0NotEqualToF1.selector, 0, 0, 1));
        fibonacci.setF0F1(0, 0);
    }

    function test_BadSequence() public {
        vm.expectRevert(abi.encodeWithSelector(Fibonacci.F1NotFibonacci.selector, 0, 1, 5));
        fibonacci.setF0F1(1, 5);
    }
}
