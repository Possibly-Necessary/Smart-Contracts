
const SecretKeeper = artifacts.require("SecretKeeper");
const Groth16Verifier = artifacts.require("Groth16Verifier");


module.exports = async function(callback) {
    try {
        const accounts = await web3.eth.getAccounts();
        const secretKeeper = await SecretKeeper.deployed();
        const verifier = await Groth16Verifier.deployed();

        // Setting the secret with ZKP proof
        console.log('Setting secret...');
        
        const secret = "SomeSecret";
        const a = [ // Was 0x0d88... --> changed to 0x0d78... to make the proof invalid
            "0x0d78044690169481fcc79c42263898bfb16d626b932b283a48e516858e5f01ad",
            "0x019ddfcee94680a59d47191728ab503ecb6c29bf2a26f9df7d752acd8cfb3a09"
        ];
        const b = [
            [
                "0x04b2ed0b1be3cd7b4e594e3816c7032df34ad4d533d54261d3ba7da840be8d38",
                "0x230a3c44d6fa28df7a90a0603480e3ff3bdaa0de7d1fbef35ecfdcd0ceae49a1"
            ],
            [
                "0x0a00bfec0c300128e9dd17baf37c93018af24c6e02c4f4ea973d70344b9d2796",
                "0x13aa31a28ad70842e5cb8087073774ff43f56bbb946119a803ec3a039af7da53"
            ]
        ];
        const c = [
            "0x09710287d5fc107e9fd0786dbdb02141a348b86b5c9b0917b1c564166a574da8",
            "0x2df3e35adc6b535090bd6f17f8b8280877083435edd2de11af680a73e2c4ff17"
        ];
        const input = [
            "0x0000000000000000000000000000000000000000000000000000000000000000"
        ];

        await secretKeeper.verifyAndReward(secret, a, b, c, input, { from: accounts[0], gas: 3000000 });

        console.log("Secret set successfully!");

        const retrievedSecret = await secretKeeper.getSecret({ from: accounts[0] });
        console.log("The secret is:", retrievedSecret);

        callback();
    } catch (error) {
        console.error("Error interacting with the contracts:", error);
        callback(error);
    }
};
