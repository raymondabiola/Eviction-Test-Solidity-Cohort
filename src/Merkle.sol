// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {MerkleProof} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import{AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract Merkle is AccessControl{

bytes32 public merkleRoot;
mapping(bytes32 => bool) public usedHashes;
event MerkleRootSet(bytes32 indexed newRoot);

bytes32 public constant OWNERS_ROLE = keccak256("OWNERS_ROLE");

constructor(){
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(OWNERS_ROLE, msg.sender);
}

 function setMerkleRoot(bytes32 root) external onlyRole(OWNERS_ROLE){
        merkleRoot = root;
        emit MerkleRootSet(root);
 }

 function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        return ECDSA.recover(messageHash, signature) == signer;
 }
}