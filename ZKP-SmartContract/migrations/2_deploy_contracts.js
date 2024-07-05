
/*
const Groth16Verifier = artifacts.require("Groth16Verifier");
const Coin = artifacts.require("Coin");
const SecretKeeper = artifacts.require("SecretKeeper");

module.exports = function(deployer) {
    // Parameters for deployment
    const rewardAmount = web3.utils.toWei("1", "ether");  // Assuming 1 ETH as reward amount
    let verifierAddress, coinAddress; // Define the address variables

    deployer.deploy(Groth16Verifier).then(function(instance) { // 'then' is used to ensure the order of the deployed contracts
        verifierAddress = instance.address; // Creating an instance 
        return deployer.deploy(Coin, rewardAmount);
    }).then(function(coinInstance) {
        coinAddress = coinInstance.address;
        return deployer.deploy(SecretKeeper, verifierAddress, rewardAmount, coinAddress);
    });
};
*/

// Declare the constant variables 'Groth16Verifier', 'Coin' and 'SecretKeeper'
const Groth16Verifier = artifacts.require("Groth16Verifier"); // For Truffle to load compiled contracts from the artifacts found in the build folder
const Coin = artifacts.require("Coin");
const SecretKeeper = artifacts.require("SecretKeeper");

module.exports = async function(deployer) { // Deployer object to handle deployment
    // Parameters for deployment
    const rewardAmount = web3.utils.toWei("1", "ether");  // Assuming 1 ETH as reward amount
    let verifierAddress, coinAddress; // Define the address variables

    // Deploy Groth16Verifier
    await deployer.deploy(Groth16Verifier).then(function(instance) { 
        verifierAddress = instance.address; // Get the address of the deployed contract
        console.log("Groth16Verifier deployed at:", verifierAddress);
    });

    // Deploy Coin contract with rewardAmount
    await deployer.deploy(Coin, rewardAmount).then(function(instance) {
        coinAddress = instance.address; // Get deployed address
        console.log("Coin deployed at:", coinAddress);
    });

    // Deploy SecretKeeper contract with verifierAddress, rewardAmount, and coinAddress
    await deployer.deploy(SecretKeeper, verifierAddress, rewardAmount, coinAddress).then(function(instance) {
        console.log("SecretKeeper deployed at:", instance.address);
    });
};
