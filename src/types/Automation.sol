// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAutomationCompatible} from "../interfaces/IAutomationCompatible.sol";

struct Automation {
    address owner;
    IAutomationCompatible target;
    bytes checkData;
    uint256 failedExec;
    uint256 lastExec;
}

using AutomationLib for Automation global;

library AutomationLib {
    modifier validatePayment(uint256 baseFee) {
        uint256 balanceBefore = address(this).balance;
        _;
        uint256 balanceAfter = address(this).balance;
        require(balanceAfter >= balanceBefore + baseFee, "Missing payment");
    }

    function checkUpkeep(Automation memory self, uint256 baseFee)
        internal
        returns (bool perform, bytes memory performData)
    {
        uint256 balance = address(self.target).balance;
        if (balance < baseFee) {
            return (false, "");
        }
        return self.target.checkUpkeep(self.checkData);
    }

    function performUpkeep(Automation memory self, bytes memory performData, uint256 baseFee)
        internal
        validatePayment(baseFee)
        returns (bool success, bytes memory returnData)
    {
        bytes memory callData = abi.encodeWithSelector(IAutomationCompatible.performUpkeep.selector, (performData));

        (success, returnData) = payable(address(self.target)).call(callData);
    }
}
