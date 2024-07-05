// Example following the Book: Build Your Own Blockchain A Practical Guide to Distributed Ledger Technology by Daniel Hellwig

/*
 This contract allows to bettors to stake a pre-defined amount, then determins randomly based on whether the block's hash is even or odd
 During the execution of this contract, it will randomely determine the winner of the coin toss (using 50:50 odds) -- it runs
 a RNG implemented by EVM
*/

pragma solidity ^0.8.0; // specify the version of Solidity compiler (follows semantic versioning: MAJOR.MINOR.PATCH)

contract Coin { // Declaring a contract names 'Coin'

    uint256 amount; // State variable called 'amount' to store the fixed betting amount required to enter the game
    uint256 blockNumber; // State variable that stores the block number after a bet is placed
    address payable[] public bettors; // Array to store the addresses of the players who enter the bet

    constructor(uint256 amount_) { // Constructor executes once the contract is deployed
        amount = amount_; // It sets the initial value of 'amount' to the value provided at the time of deployment
    }

    // Function that receives Ether (as indicated by the 'payable' keyword)
    // Function is called by the players to place their bets
    function bet() payable public {
        require(msg.value == amount); // Checks if the Ether sent through calling this function is equal to the 'amount'
        require(bettors.length < 2); // Restricts that no more than two players can bet
        blockNumber = block.number + 1; // Predicts/anticipates that the toss will happen in a future block (results cannot be known ahead of time)
        bettors.push(payable(msg.sender));
    }

    // Public function that determines the winner; function is called after both bets are placed
    function toss()public {
        require(bettors.length == 2); // Two bets must be placed, otherwise the toss function cannot be executed
        require(blockNumber < block.number); //
        // Winner is determined by taking the hash of the current block (convert to unsigned int, and take modulus)
        uint256 winner = uint256(blockhash(block.number)) % 2; // Result will be either 0 or 1 which will correspond to the indices of the 'bettors' array
        // Transfers the Ether held by the contract (total bet amount) to the winning player
        bettors[winner].transfer(address(this).balance); // 'address(this).balance' represents the current balance of the contract

        // Reset state
        delete bettors; //Clear the bettors array
        blockNumber = 0; 
    }
}
