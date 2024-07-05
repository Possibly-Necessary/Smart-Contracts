const SecretKeeper = artifacts.require("SecretKeeper");
const Groth16Verifier = artifacts.require("Groth16Verifier");


module.exports = async function(deployer) {
    let verifierAddress
    await deployer.deploy(Groth16Verifier).then(function(instance) { 
        verifierAddress = instance.address; // Get deployed address
        console.log("Groth16Verifier deployed at:", verifierAddress);
    });
    await deployer.deploy(SecretKeeper, verifierAddress).then(function(instance) {
        console.log("SecretKeeper deployed at:", instance.address);
    });
};
