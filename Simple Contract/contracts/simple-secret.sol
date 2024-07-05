pragma solidity ^0.8.0;

import "./verifier.sol";

contract SecretKeeper { 
    string private _secret; 
    address private _owner; 
    bytes32 private _secretHash; 
    Groth16Verifier private verifier; 

    constructor(address verifierAddress) {
        _owner = msg.sender; 
        verifier = Groth16Verifier(verifierAddress); 
    }
 
    modifier onlyOwner() {
        require(msg.sender == _owner, 
        "Ownable: caller is not the owner");
        _; 
    }

    function verifyAndReward(
        string calldata secret,
        uint256[2] calldata a, 
        uint256[2][2] calldata b, 
        uint256[2] calldata c,
        uint256[1] calldata input
    ) external onlyOwner {

        require(verifier.verifyProof(a, b, c, input), "Invalid Proof"); 
        _secret = secret;
        _secretHash = keccak256(abi.encodePacked(secret));

    }

    function setSecret(string calldata secret) external onlyOwner {
        _secret = secret;
        _secretHash = keccak256(abi.encodePacked(secret));
    }

    function getSecret() external view onlyOwner returns (string memory) {
        return _secret;
    }

    function owner() public view returns (address) { 
        return _owner;
    }
}



