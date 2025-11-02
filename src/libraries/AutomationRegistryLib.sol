// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Automation} from "../types/Automation.sol";

import {Test, console} from "forge-std/Test.sol";

struct Config {
    uint256 automationFee;
    uint8 maxFailures;
}

library AutomationRegistryLib {
    function modifyRegistry(Automation[10] storage registry, uint256 index, Automation memory newAutomation) internal {
        registry[index] = newAutomation;
    }

    function registerAutomation(Automation[10] storage registry, uint256 index, Automation memory newAutomation)
        internal
    {
        require(registry[index].owner == address(0), "Not avalable");
        registry[index] = newAutomation;
    }

    function executeAutomation(Automation[10] storage registry, Config memory config) internal {
        for (uint16 i = 0; i < registry.length; i++) {
            Automation memory automation = registry[i];
            if (address(automation.target) == address(0)) {
                continue;
            }
            (bool perform, bytes memory performData) = automation.checkUpkeep(config.automationFee);
            if (perform) {
                (bool success,) = automation.performUpkeep(performData, config.automationFee);
                automation.lastExec = block.timestamp;
                if (success) {
                    automation.failedExec = 0;
                } else {
                    automation.failedExec += 1;
                }
                if (automation.failedExec == config.maxFailures) {
                    delete registry[i];
                } else {
                    modifyRegistry(registry, i, automation);
                }
            }
        }
    }
}
