// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;
import "../src/Vault.sol";

contract Transactions is EvictionVault{

 struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    mapping(uint256 => Transaction) public transactions;

    uint256 public txCount;
    bool public paused;

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    error WaitForExecutionTime();
    error TransactionIsExecuted();
    error TransactionConfirmedByCaller();
    error NeedMoreConfirmations();
    error TransactionFailed();
    error VaultIsPaused();
    error NotOwner();

constructor(address transactionAddr, address merkleAddr, address[] memory _owners, uint256 _threshold)EvictionVault(transactionAddr, merkleAddr, _owners, _threshold) {}


    function submitTransaction(address to, uint256 value, bytes calldata data) external {
        if(paused) revert VaultIsPaused();
        if(!isOwner[msg.sender]) revert NotOwner();
        uint256 id = txCount++;
        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });
        confirmed[id][msg.sender] = true;
        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external {
        if(paused) revert VaultIsPaused();
        if(!isOwner[msg.sender]) revert NotOwner();
        Transaction storage txn = transactions[txId];
        if(txn.executed) revert TransactionIsExecuted();
        if(confirmed[txId][msg.sender])revert TransactionConfirmedByCaller();
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }

     function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];
        if(txn.confirmations < threshold) revert NeedMoreConfirmations();
        if(txn.executed) revert TransactionIsExecuted();
        if(block.timestamp < txn.executionTime) revert WaitForExecutionTime();
        txn.executed = true;
        (bool s,) = payable(txn.to).call{value: txn.value}(txn.data);
        if(!s) revert TransactionFailed();
        emit Execution(txId);
    }

    function pause() external {
        if(!isOwner[msg.sender])revert NotOwner();
        paused = true;
    }

    function unpause() external {
        if(!isOwner[msg.sender]) revert NotOwner();
        paused = false;
    }
}