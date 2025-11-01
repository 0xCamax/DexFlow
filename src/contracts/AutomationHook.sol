// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseHook, PoolKey, SwapParams, BalanceDelta, BeforeSwapDelta} from "./BaseHook.sol";
import {Automation} from "../types/Automation.sol";


contract AutomationHook is BaseHook {

    

    constructor(address poolManager) BaseHook(poolManager) {

    }

    function _beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // check for automations
    }


}
