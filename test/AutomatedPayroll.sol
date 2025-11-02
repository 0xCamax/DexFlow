// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAutomationCompatible} from "../src/interfaces/IAutomationCompatible.sol";
import {DexFlow} from "../src/DexFlow.sol";

struct Payroll {
    address target;
    uint256 amount;
    uint256 paymentInterval;
    uint256 lastPayment;
}

event Success(bool);

contract AutomatedPayroll is IAutomationCompatible {
    address public immutable owner;

    Payroll[10] internal payroll;

    DexFlow executor;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    function setExecutor(address payable _executor) external onlyOwner {
        executor = DexFlow(_executor);
    }

    function checkUpkeep(bytes memory /*checkData*/ ) public view returns (bool, bytes memory) {
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
        _requireCheckUpkeep();
        for (uint8 i = 0; i < payroll.length; i++) {
            if (_requiresPayment(payroll[i])) {
                Payroll memory _payroll = payroll[i];
                _pay(_payroll);
                _payroll.lastPayment = block.timestamp;
                payroll[i] = _payroll;
            }
        }
        uint256 fee = executor.getFee();

        (bool success,) = payable(address(executor)).call{value: fee}("");
        
        emit Success(success);
    }

    function modifyPayroll(Payroll memory _payroll, uint8 index) external onlyOwner {
        _modifyPayroll(_payroll, index);
    }

    function _requiresPayment(Payroll memory _payroll) internal view returns (bool) {
        if (_payroll.target == address(0) || _payroll.paymentInterval == 0) return false;
        if (block.timestamp <= _payroll.lastPayment) return false;
        return (block.timestamp - _payroll.lastPayment) > _payroll.paymentInterval;
    }

    function _pay(Payroll memory _payroll) internal returns (bool success, bytes memory returnData) {
        (success, returnData) = payable(_payroll.target).call{value: _payroll.amount}("");
    }

    function _requireCheckUpkeep() internal view {
        (bool perform,) = checkUpkeep("");
        require(perform, "Not necessary");
    }

    function _modifyPayroll(Payroll memory _payroll, uint8 index) internal {
        payroll[index] = _payroll;
    }
}
