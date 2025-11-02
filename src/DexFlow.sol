// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./contracts/AutomationHook.sol";

contract DexFlow is AutomationHook {
    using AutomationRegistryLib for Automation[10];

    event PaymentReceived(address from, uint256 amount);

    constructor(address poolManager, address owner) AutomationHook(poolManager, owner) {}

    function registerAutomation(uint8 id, Automation memory newAutomation) public {
        automationRegistry.registerAutomation(id, newAutomation);
    }

    function cancelAutomation(uint8 id) public {
        Automation memory automation = automationRegistry[id];
        require(msg.sender == automation.owner, "Not allowed");
        delete automationRegistry[id];
    }

    function claimAutomationFees(address to) internal onlyOwner returns (bool success) {
        (success,) = payable(to).call{value: address(this).balance}("");
    }

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }
}
