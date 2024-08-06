// SPDX-License-Identifier: MIT
// Source: https://github.com/chatch/hashed-timelock-contract-ethereum/blob/master/contracts/HashedTimelock.sol
pragma solidity ^0.8.0;

import "./verifier.sol"; // Importing ZoKrates solidity verifier

// Contract definition
contract VerifyAndExchangeHTLC {

    // Variable of type 'Verifier' which comes from the ZoKrates verifer smart contract
    Verifier private immutable _verifier;
    address private immutable _owner;

    // Hash value computed in ZoKrates using Poseidon's hash
    // bytes32 public constant HASH_VALUE = bytes32(13432747890427498375149439507741491713221934456011451209707589675527438237343);
    // bytes32 public constant HASH_VALUE = 0x1db2aa76f5442e63d3691e410bfed3144eb2e0b45fcfe41a65eb83c53e7e7e9f; // The hash from the inputs part of ZoKrates proof file
    struct LockContract {
        uint256 amount;
        uint256 timeLock;
        bool withdrawn;
        bool refunded;
        address payable sender;
        address payable receiver;
        bytes32 hashLock;
    }

    mapping(bytes32 => LockContract) public contracts;

    // Events that are logged on the Ethereum blockchain
    event HTLCCreated(bytes32 indexed contractId, address indexed sender, address indexed receiver, uint256 amount, uint256 timeLock);
    event HTLCWithdrawn(bytes32 indexed contractId, address indexed receiver, uint256 amount);
    event HTLCRefunded(bytes32 indexed contractId, address indexed sender, uint256 amount);

    constructor(address verifierAddress) {
        _verifier = Verifier(verifierAddress);
        _owner = msg.sender; // Set the address of the user who deployed this contract as the owenr of this contract
    }
    // Lock ETH in the contract (using the predefined Poseidon's hash for the hashLock
    function createHTLC(address payable receiver, uint256 timelock, bytes32 hashLock) external payable returns (bytes32 contractId){
        require(msg.value > 0, "Cannot lock on zero ETH");
        require(timelock > block.timestamp, "Timelock must be in the future");

        contractId = keccak256(abi.encodePacked(msg.sender, receiver, msg.value, hashLock, timelock)); 

        require(contracts[contractId].amount == 0, "Contract with this ID already exists");

        contracts[contractId] = LockContract({
            amount: msg.value,
            timeLock: timelock,
            withdrawn: false,
            refunded: false,
            sender: payable(msg.sender),
            receiver: receiver,
            hashLock: hashLock
        });

        emit HTLCCreated(contractId, msg.sender, receiver, msg.value, timelock);
    }

    // Claim ETH after validating ZoKrates proof and the public hash
    // Replaced the preImage type from bytes32 to 'string memory' to work with the interact.js script
    function withdraw(bytes32 contractId, uint256[2] calldata a, uint256[2][2] calldata b, uint256[2] calldata c, uint256[5] calldata input, string memory preImage) external {

        // For the ZoKrates verifier 'verifyTx' function
        Verifier.Proof memory proof = Verifier.Proof({
            a: Pairing.G1Point(a[0], a[1]),
            b: Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]),
            c: Pairing.G1Point(c[0], c[1])
        });

        LockContract storage lock = contracts[contractId];
        require(lock.receiver == msg.sender, "Only the receiver can withdraw");
        require(lock.timeLock > block.timestamp, "Time lock expired");
        require(!lock.withdrawn && !lock.refunded, "Already withdrawn");
        require(_verifier.verifyTx(proof, input), "Invalid Proof"); // Call the ZoKrates verifiyTx function to verify the proof
        require(keccak256(abi.encodePacked(preImage)) == lock.hashLock, "Invalid pre-image"); // Must provide h = keccakHash(k), where k is the secret (in interact.js--- the pre-image is a string word)
        //bool isValid = verifier.verifyProof(a, b, cProof, input);
        //require(isValid, "Invalid Proof");

        lock.withdrawn = true;
        //lock.preImage = preImage;

        uint256 amount = lock.amount;
        (bool sent, ) = lock.receiver.call{value: amount}("");
        require(sent, "Failed to send ETH");

        emit HTLCWithdrawn(contractId, msg.sender, amount);
    }

    // Refund ETH after Timelock has expired 
    function refund(bytes32 contractId) external {
        //bytes32 hash = bytes32(HASH_VALUE);
        //Lock storage lock = locks[hash];

        LockContract storage lock = contracts[contractId];
        require(lock.sender == msg.sender, "Only the sender can refund");
        require(lock.timeLock <= block.timestamp, "Time lock has not expired");
        require(!lock.withdrawn && !lock.refunded, "Already refunded");
        //delete locks[hash];
        lock.refunded = true;

        uint256 amount = lock.amount;
        (bool sent, ) = lock.sender.call{value: amount}("");
        require(sent, "Failed to refund ETH");

        emit HTLCRefunded(contractId, msg.sender, amount);
    }


    // Get contract's details
    function getContract(bytes32 contractId) external view returns (address sender, address receiver, uint256 amount, uint256 timelock, bool withdrawn, bool refunded, bytes32 preImage) {
        LockContract storage lock = contracts[contractId];
        return (lock.sender, lock.receiver, lock.amount, lock.timeLock, lock.withdrawn, lock.refunded, lock.hashLock);
    }

    // Check the contract's balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}