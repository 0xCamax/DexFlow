// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAutomationCompatible} from "../src/interfaces/IAutomationCompatible.sol";

import {Test, console} from "forge-std/Test.sol";

struct Payroll {
    address target;
    uint256 amount;
    uint256 paymentInterval;
    uint256 lastPayment;
}

contract AutomatedPayroll is IAutomationCompatible {
    address public immutable owner;

    Payroll[10] internal payroll;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    function checkUpkeep(bytes calldata /*checkData*/ ) external view returns (bool, bytes memory) {
        uint256 i = 0;
        bool perform;
        bytes memory performData;
        while (true) {
            perform = _requiresPayment(payroll[i]);
            if (perform) {
                break;
            }
            i++;
        }
        return (perform, performData);
    }

    function performUpkeep(bytes calldata /*performData*/ ) external {
        for (uint8 i = 0; i < payroll.length; i++) {
            _pay(payroll[i]);
        }
    }

    function modifyPayroll(Payroll memory _payroll, uint8 index) external onlyOwner {
        payroll[index] = _payroll;
    }

    function _requiresPayment(Payroll memory _payroll) internal view returns (bool) {
        return block.timestamp - _payroll.lastPayment > _payroll.paymentInterval;
    }

    function _pay(Payroll memory _payroll) internal returns (bool success, bytes memory returnData) {
        (success, returnData) = payable(_payroll.target).call{value: _payroll.amount}("");
    }
}
