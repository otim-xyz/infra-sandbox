// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Fibonacci} from "../src/Fibonacci.sol";

contract Deploy is Script {
    Fibonacci public fibonacci;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        fibonacci = new Fibonacci();
        vm.stopBroadcast();
    }
}
