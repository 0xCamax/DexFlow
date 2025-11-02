// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/DexFlow.sol";
import "../src/utils/Constants.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {Hooks, IHooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";


import {Helpers} from "../script/Helpers.s.sol";

import {Test, console} from "forge-std/Test.sol";

contract Deployment is Test, ArbitrumConstants, Helpers {
    DexFlow internal dexFlow;
    uint256 internal deployerPrivateKey;
    address testAccount;


    function setUp() public {
        vm.createSelectFork("arbitrum");
        testAccount = address(this);

        // Fund the test account with ETH
        vm.deal(testAccount, 1000 ether);

    }

    function test_deploy() public {
        dexFlow = _deploy(testAccount);
    }
}
