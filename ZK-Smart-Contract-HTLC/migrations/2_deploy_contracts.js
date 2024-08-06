const Verifier = artifacts.require("Verifier");
const VerifyAndExchangeHTLC = artifacts.require("VerifyAndExchangeHTLC");

module.exports = function(deployer) {
    deployer.deploy(Verifier).then(function() {
        return deployer.deploy(VerifyAndExchangeHTLC, Verifier.address);
    });
};
