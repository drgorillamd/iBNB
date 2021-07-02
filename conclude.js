const Web3 = require('web3');
const Provider = require('@truffle/hdwallet-provider');
const Presale_contract = require('./build/contracts/iBNB_presale.json');
const Token_contract = require('./build/contracts/iBNB.json')
const fs = require('fs');
const airdrops = require("./airdrop.json")

const tmp = fs.readFileSync("/home/drgorilla/Documents/solidity/.private_key_testnet").toString();
const owner = [tmp];
//const RPC_SERVER = 'https://bsc-dataseed.binance.org';
const RPC_SERVER = 'https://data-seed-prebsc-1-s1.binance.org:8545/';

async function main() {
  try {
     
    const provider = new Provider(owner, RPC_SERVER);
    const web3 = new Web3(provider);

    const t = await new web3.eth.Contract(Token_contract.abi, Token_contract.networks[97].address); //56
    const p = await new web3.eth.Contract(Presale_contract.abi, Presale_contract.networks[97].address);

    p.methods.concludeAndAddLiquidity().send({from: provider.addresses[0]})
    .then(x => t.methods.setCircuitBreaker(false).send({from: provider.addresses[0], gasPrice: web3.toWei(200000000, 'gwei')}))
    .catch(error => console.log(error));

  } catch (e) {
    console.log(e);
  }
}

main();