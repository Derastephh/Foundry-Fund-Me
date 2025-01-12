// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;

    address DERA = makeAddr("dera");
    uint256 constant VALUE = 0.5 ether;
    uint256 constant MIN_VALUE = 5e18;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(DERA, STARTING_BALANCE);
    }

    function testMinUsd() public {
        assertEq(fundme.MIN_USD(), MIN_VALUE);
    }

    function testGetOwner() public {
        console.log(fundme.getOwner());
        console.log(msg.sender);
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceVersion() public {
        uint256 version = fundme.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function testFund() public {
        vm.expectRevert();
        fundme.fund();
    }

    function testGetAddressToAmountFunded() public {
        vm.prank(DERA);
        fundme.fund{value: VALUE}();
        uint256 amount = fundme.getAddressToAmountFunded(DERA);
        assertEq(amount, VALUE);
    }

    function testGetFunders() public {
        vm.prank(DERA);
        fundme.fund{value: VALUE}();
        address fundee = fundme.getFunders(0);
        assertEq(fundee, DERA);
    }

    modifier funded() {
        vm.prank(DERA);
        fundme.fund{value: VALUE}();
        _;
    }

    function testWithdrawNotOwner() public funded {
        vm.prank(DERA);
        vm.expectRevert();
        fundme.withdraw();
        assertEq(address(fundme).balance, VALUE);
    }

    function testOwnerCanWithdraw() public funded {
        uint256 balanceOwner = fundme.getOwner().balance;
        uint256 balanceContract = address(fundme).balance;
        console.log(balanceOwner);
        console.log(balanceContract);

        vm.prank(fundme.getOwner());
        fundme.withdraw();

        uint256 endBalanceOwner = fundme.getOwner().balance;
        uint256 endBalanceContract = address(fundme).balance;
        console.log(endBalanceOwner);
        console.log(endBalanceContract);
        assertEq(endBalanceContract, 0);
        assertEq(balanceOwner + balanceContract, fundme.getOwner().balance);
    }

    function testMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 fundersIndex = 2;
        for (uint160 i = fundersIndex; i < numberOfFunders; i++) {
            hoax(address(i), VALUE);
            fundme.fund{value: VALUE}();
        }
        uint256 balanceOwner = fundme.getOwner().balance;
        uint256 balanceContract = address(fundme).balance;

        vm.prank(fundme.getOwner());
        fundme.withdraw();

        uint256 endBalanceOwner = fundme.getOwner().balance;
        uint256 endBalanceContract = address(fundme).balance;

        assertEq(endBalanceContract, 0);
        assertEq(balanceOwner + balanceContract, fundme.getOwner().balance);
    }
}
