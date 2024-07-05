
pragma solidity ^0.8.0;

// Import the ZKP smart contract generated from Circom 2
import "./verifier.sol";
import "./coin-toss.sol"; // Import the coin-toss contract

contract SecretKeeper { // Defining a contract names 'SecretKeeper'

    // State variables (below) are stored on the blockchain
    // Variables of type secret cannot be accessed directly by external contracts/accounts
    string private _secret; // to store the secret message
    address private _owner; // to store the address of the owner
    bytes32 private _secretHash; // to store the hash of the message

    // Variable of type 'Groth16Verifier' --> this comes from the smart contract generated from Circom
    Groth16Verifier private verifier; 

    // For the coin-toss contract
    uint256 public _rewardAmount;
    address payable public _coinContract; // 'address payable' variable to specify address of the coin contract that can receive ether

    // Constructer function executes once the contract is deployed
    constructor(address verifierAddress, uint256 rewardAmount, address payable coinContract) {
        _owner = msg.sender; // Sets the address of the user who deployed the contract to the '_owner' variable
        // Initialize the verifier contract
        verifier = Groth16Verifier(verifierAddress); 

        _rewardAmount = rewardAmount;
        _coinContract = coinContract;
    }

    // Function Modifier (adds pre-checks to functions) - 1) if the function that uses this modifier is not called by the owner
    modifier onlyOwner() {
        require(msg.sender == _owner, // 2) this will return false -- and will revert the transaction
        "Ownable: caller is not the owner");
        _; // the functions that use 'onlyOwner' would not execute. For instance, the 'setSecret()' function
    }

    // Function that only allows the owner to set a secret message without the need to provide a SAT proof
    function setSecret(string calldata secret) external onlyOwner {
        _secret = secret;
        _secretHash = keccak256(abi.encodePacked(secret));
    }

    // Function that returns the secret hash (getter function)
    // 'view' modifier indicates that this function does not alter the state of the hash, only reads it from the blockchain (read-only function)
    //function getSecretHash() external view returns (bytes32) { 
       // return _secretHash;
    //}

    // Function to prove knowledge of the message 
    // String of type 'calldata' because data being passed for this function is not part of the contracts persistant storage
    function proveKnowledge(string calldata secret) external view returns (bool) {
        return keccak256(abi.encodePacked(secret)) == _secretHash; // Checking against the state variable '_secretHash'
    }

    // Function that anyone can call and set a secret message if a valid SAT proof is provided
    function verifyAndReward(
        string calldata secret,
        uint256[2] calldata a, // a, b, c, input are input arguments that are required by the verifyProof() in the generated Circom ZKP verifier contract
        uint256[2][2] calldata b, // These can be found in the input.json and proof.json files generated when compiling the Circom ZKP circuit
        uint256[2] calldata c,
        uint256[1] calldata input
    ) external {
        //Verify the proof using the Circom generated ZKP smart contract proof
        require(verifier.verifyProof(a, b, c, input), "Invalid Proof"); // Using the 'verifier' object and accessing the verifyProof() funciton in the Circom ZKP contract

        // Check if the user knows the secret message
        if (keccak256(abi.encodePacked(secret)) == _secretHash) {
            // Transfer reward to user if everything checks out
            require(address(this).balance >= _rewardAmount, "Not enough eth.."); // If this returns fales, then "Not enough eth.." will be returned
            payable(msg.sender).transfer(_rewardAmount);

        } else { // If users do not know the secret message, but have a valid proof, a betting game between this contract and the user takes place
            
            // Call the bet funcion in the coin-toss contract
            Coin coinInstance = Coin(_coinContract); // Instantiate the Coin contract instance and pass in the address of the coin contract
            coinInstance.bet{value: _rewardAmount}(); // Place a bet

            // Toss a coin by calling the 'toss' function in the coin toss contract
            coinInstance.toss();

            // Outcome after coin toss
            uint256 contractBalance = address(this).balance; // eth balance of this contract (not the owner)

            if (contractBalance > 0) { // The contract balance is > 0, remaining balance is sent to the owner
                // transfer ether from this contact's balance to the owner of this contract
                payable(_owner).transfer(contractBalance); // Convert the '_owner' 'address' type to a 'payable address' to receive ether
            } else {
                // Nothing happens -- user won, hence contract balance is 0
            }
        }
    }
    // Function that sets the owner of the SecretKeeper contract to the address that deployed the contract
    // Public function that can be called within this contract and other contracts (maximum accessibility)
    function owner() public view returns (address) { // It returns a value of type address
        return _owner;
    }

    // Allow this contract to receive eth
    receive() external payable{}
}

// Interface definition: allows this contract to call/interact with external functions/smart contracts
interface ICoin {
    function bet() external payable; // Allow this contract to call the bet function and send ether to it
    function toss() external; // Allow this contract to trigger the toss function of the coin toss contract contract
}
