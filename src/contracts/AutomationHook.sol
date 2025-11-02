// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseHook, PoolKey, SwapParams, BalanceDelta, BeforeSwapDelta} from "./BaseHook.sol";
import {toBeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Automation} from "../types/Automation.sol";
import {AutomationRegistryLib, Config} from "../libraries/AutomationRegistryLib.sol";

contract AutomationHook is BaseHook {
    using AutomationRegistryLib for Automation[10];

    Automation[10] public automationRegistry;
    address public immutable owner;
    Config public config;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    constructor(address poolManager, address _owner) BaseHook(poolManager) {
        owner = _owner;
        config = Config({automationFee: 0.0001 ether, maxFailures: 3});
    }

    function setConfig(Config memory newConfig) public onlyOwner {
        config = newConfig;
    }

    function getFee() public view returns (uint256) {
        return config.automationFee;
    }

    function _beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        automationRegistry.executeAutomation(config);
        return (this.beforeSwap.selector, toBeforeSwapDelta(0, 0), 0);
    }
}
