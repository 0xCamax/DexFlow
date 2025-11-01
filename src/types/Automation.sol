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

    function modifyAutomation(Automation[10] storage registry, uint256 index, Automation memory newAutomation)
        internal
    {
        require(msg.sender == registry[index].owner, "not allowed");
        registry[index] = newAutomation;
    }

    function executeAutomation(Automation[10] storage registry, uint256 baseFee) internal {
        for (uint16 i = 0; i < registry.length; i++) {
            Automation memory automation = registry[i];
            (bool perform, bytes memory performData) = checkUpkeep(automation, baseFee);
            if (perform) {
                (bool success,) = performUpkeep(automation, performData, baseFee);
                automation.lastExec = block.timestamp;
                if (success) {
                    automation.failedExec = 0;
                } else {
                    automation.failedExec += 1;
                }
                modifyAutomation(registry, i, automation);
            }
        }
    }
}
