// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/DexFlow.sol";
import {IAutomationCompatible} from "../src/interfaces/IAutomationCompatible.sol";
import {AutomatedPayroll, Payroll} from "./AutomatedPayroll.sol";
import {Helpers} from "../script/Helpers.s.sol";

contract MainTests is Test, Helpers {
    DexFlow public dexFlow;
    IAutomationCompatible public target;
    address testAccount;
    AutomatedPayroll internal automatePayroll;

    function setUp() public {
        vm.createSelectFork("arbitrum");
        testAccount = address(this);
        _fundAccount(testAccount);
        dexFlow = _deploy(testAccount);

        automatePayroll = new AutomatedPayroll(testAccount);
        automatePayroll.modifyPayroll(Payroll(address(DEV), 1 ether, 10 seconds, 0), 0);
        vm.deal(address(automatePayroll), 1000 ether);

        _configurePoolKeys(1000, 1, address(dexFlow));
        _setupApprovals(address(dexFlow));
        _initializePool();
        _addLiquidity(10_000_000);

        // struct Automation {
        //     address owner;
        //     IAutomationCompatible target;
        //     bytes checkData;
        //     uint256 failedExec;
        //     uint256 lastExec;
        // }

        dexFlow.registerAutomation(0, Automation(msg.sender, IAutomationCompatible(automatePayroll), "", 0, 0));
        automatePayroll.setExecutor(payable(address(dexFlow)));
    }

    function test_checkUpkeep() public view {
        (bool perform,) = automatePayroll.checkUpkeep("");
        assertEq(perform, true, "Not true");
    }

    function test_performUpkeep() public {
        uint256 balanceBefore = DEV.balance;
        (, bytes memory performData) = automatePayroll.checkUpkeep("");
        automatePayroll.performUpkeep(performData);
        assertGt(DEV.balance, balanceBefore, "Payment required");
    }

    function test_validatePayment() public {}

    function test_automation() public {
        (bool perform,) = automatePayroll.checkUpkeep("");
        assertEq(perform, true, "Not true");

        uint256 balanceBefore = DEV.balance;

        uint256 currentBlock = block.timestamp;

        _swap(1, true);

        currentBlock += 6 seconds;

        vm.warp(currentBlock);
        vm.expectRevert();
        _swap(1, true);

        currentBlock += 6 seconds;

        vm.warp(currentBlock);
        _swap(1, true);

        console.log("Dev balance:", DEV.balance);
        console.log("Hook balance:", address(dexFlow).balance);

        assertGt(DEV.balance, balanceBefore, "Payment required");
    }

    function _fundAccount(address account) public {
        vm.deal(account, 1000 ether);

        vm.startPrank(WHALE);
        uint256 usdcAmount = 10_000_000 * 1e6;
        require(USDC.balanceOf(WHALE) >= usdcAmount, "Whale has insufficient USDC");
        USDC.transfer(testAccount, usdcAmount);
        vm.stopPrank();
    }
}
