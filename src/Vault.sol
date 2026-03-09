// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "../src/Merkle.sol";
import "../src/Transactions.sol";

contract EvictionVault {
Merkle public merkle;
Transactions public transaction;

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public confirmed;

    mapping(address => uint256) public balances;


    mapping(address => bool) public claimed;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    uint256 public totalVaultValue;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    
    event Claim(address indexed claimant, uint256 amount);

    error TransactFailed();
    error NoOwners();
    error ZeroAddressInOwnersArray();
    error Paused();
    error InsufficientBalance();
    error InvalidLeaf();
    error AlreadyClaimed();
    error NotAnOwner();


    constructor(address transactionAddr, address merkleAddr, address[] memory _owners, uint256 _threshold) payable {
        transaction = Transactions(payable(transactionAddr)); 
        merkle = Merkle(merkleAddr);
        if(_owners.length == 0) revert NoOwners();
        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            if(o == address(0)) revert ZeroAddressInOwnersArray();
            isOwner[o] = true;
            owners.push(o);
        }
        totalVaultValue = msg.value;
    }

    function setTransactionsAddr(address _address)public {
        transaction = Transactions(payable(_address));
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        if(transaction.paused()) revert Paused();
        if(balances[msg.sender] < amount) revert InsufficientBalance();
        balances[msg.sender] -= amount;
        totalVaultValue -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) revert TransactFailed();
        emit Withdrawal(msg.sender, amount);
    }


    function claim(bytes32[] calldata proof, uint256 amount) external {
        if(transaction.paused()) revert Paused();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 computed = MerkleProof.processProof(proof, leaf);
        if(computed != merkle.merkleRoot()) revert InvalidLeaf();
        if(claimed[msg.sender]) revert AlreadyClaimed();
        claimed[msg.sender] = true;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) revert TransactFailed();
        totalVaultValue -= amount;
        emit Claim(msg.sender, amount);
    }


    function emergencyWithdrawAll() external {
        if(!isOwner[msg.sender]) revert NotAnOwner();
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!success) revert TransactFailed();
        totalVaultValue = 0;
    }

}