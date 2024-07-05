const SecretKeeper = artifacts.require("SecretKeeper");
const Groth16Verifier = artifacts.require("Groth16Verifier");
const Coin = artifacts.require("Coin");

module.exports = async function(callback) {
    try {
        const accounts = await web3.eth.getAccounts();
        const secretKeeper = await SecretKeeper.deployed();
        const verifier = await Groth16Verifier.deployed();
        const coin = await Coin.deployed();

        // Interacting with the main contract
        console.log('Setting secret...'); // Print
        await secretKeeper.setSecret("SomeSecret", { from: accounts[0] });

        // Log initial contract balance
        let balance = await web3.eth.getBalance(secretKeeper.address);
        console.log("Initial Balance:", web3.utils.fromWei(balance, "ether"), "ETH");

        // Fund the contract
        console.log("Fund the Contract..");
        await web3.eth.sendTransaction({ from: accounts[0], to: secretKeeper.address, value: web3.utils.toWei("4", "ether"), gas:3000000 });
        
        // Log balance after funding
        balance = await web3.eth.getBalance(secretKeeper.address);
        console.log("Updated Balance:", web3.utils.fromWei(balance, "ether"), "ETH");

        
        console.log('Proving knowledge...');
        const isKnown = await secretKeeper.proveKnowledge("SomeSecret"); // Interact with the proveKnowledge function
        console.log("Is the secret known?", isKnown);

        // Verifying and rewarding -- take values for the proof from 'snarkjs generatecall'
        const a = [
            "0x0d88044690169481fcc79c42263898bfb16d626b932b283a48e516858e5f01ad",
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
        const input =  [
            "0x0000000000000000000000000000000000000000000000000000000000000000"
        ];

        await secretKeeper.verifyAndReward("SomeSecret", a, b, c, input, { from: accounts[0], gas: 3000000 });

        // Interacting with the Coin contract
        //await coin.bet({ from: accounts[0], value: web3.utils.toWei("1", "ether"), gas: 3000000 });
        //await coin.toss({ from: accounts[0], gas: 3000000 });

        console.log('Placing bet from first user...');
        await coin.bet({ from: accounts[0], value: web3.utils.toWei("1", "ether"), gas: 3000000 });

        console.log('Placing bet from second user...');
        await coin.bet({ from: accounts[1], value: web3.utils.toWei("1", "ether"), gas: 3000000 });

        console.log('Flipping coin...');
        await coin.toss({ from: accounts[0], gas: 3000000 });

        callback();
    } catch (error) {
        console.error("Error interacting with the contracts:", error);
        callback(error);
    }
};
