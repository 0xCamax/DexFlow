// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/DexFlow.sol";
import "../src/utils/Constants.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {Hooks, IHooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {Helpers} from "./Helpers.s.sol";
import {AutomatedPayroll} from "../test/AutomatedPayroll.sol";

import {Script, console} from "forge-std/Script.sol";

contract Deployment is Script, ArbitrumConstants, Helpers {
    DexFlow internal dexFlow;
    uint256 internal deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    }

    function run() public {
        vm.startBroadcast();
        dexFlow = _deploy(DEV);
        AutomatedPayroll testAutomation = new AutomatedPayroll(DEV);

        console.log(address(dexFlow));
        console.log(address(testAutomation));
    }
}
