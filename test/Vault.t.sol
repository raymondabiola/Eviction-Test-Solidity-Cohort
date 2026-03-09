// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {EvictionVault} from "../src/Vault.sol";
import {Transactions} from "../src/Transactions.sol";
import {Merkle} from "../src/Merkle.sol";
import {console} from "forge-std/console.sol";

contract EvictionVaultTest is Test {
    EvictionVault public evictionVault;
    Transactions public transactions;
    Merkle public merkle;

    address public owner1;
    address public owner2;
    address public owner3;
    address public owner4;
    address public zeroAddress;
    address[] owners;

    error InsufficientBalance();

    function setUp() public {

        owner1 = address(this);
        owner2 = makeAddr("owner2");
        owner3 = makeAddr("owner3");
        owner4 = makeAddr("owner4");
        zeroAddress = address(0);

     owners.push(owner1);
     owners.push(owner2);
     owners.push(owner3);
     owners.push(owner4);

        vm.deal(owner1, 100 ether);
        vm.startPrank(owner1);
        evictionVault = new EvictionVault{value: 20}(owners, 3);
        transactions = new Transactions(owners, 3);
        merkle = new Merkle();
        vm.stopPrank();

        console.log("owner1 address", owner1);
        console.log("owner2 address", owner2);
        console.log("owner3 address", owner3);
        console.log("owner4 address", owner4);
    }

    function testSetUpWorkedCorrectly() public{
        assertEq(evictionVault.totalVaultValue(), 20);
        assertTrue(evictionVault.isOwner(owner1));
        assertTrue(evictionVault.isOwner(owner2));
        assertTrue(evictionVault.isOwner(owner3));
        assertTrue(evictionVault.isOwner(owner4));
    }

    function testDeposit() public {
        vm.deal(owner2, 20 ether);
        vm.prank(owner2);
        evictionVault.deposit{value: 10}();
        assertEq(evictionVault.balances(owner2), 10);
        assertEq(evictionVault.totalVaultValue(), 30);
    }

    function testWithdraw() public {
        vm.deal(owner2, 20 ether);
        vm.prank(owner2);
        evictionVault.deposit{value: 10}();

        vm.expectRevert(InsufficientBalance.selector);
        vm.prank(owner2);
        evictionVault.withdraw(20 ether);

        uint owner2BalBefore = owner2.balance;
        evictionVault.withdraw(4 ether);
        uint owner2BalAfter = owner2.balance;
        assertEq(evictionVault.balances(owner2), 6 ether);
        assertEq(owner2BalAfter-owner2BalBefore, 4 ether);

    }
}
