const Web3 = require('web3');
const Provider = require('@truffle/hdwallet-provider');
const Airdrop_contract = require('./build/contracts/iBNB_airdrop.json');
const Token_contract = require('./build/contracts/iBNB.json')
const fs = require('fs');
const airdrops = require("./airdrop.json")
//const airdrops = require("./TEST airdrop TEST.json")



const tmp = fs.readFileSync("/home/drgorilla/Documents/solidity/.private_key_testnet").toString();
//const tmp = fs.readFileSync("/home/drgorilla/Documents/solidity/.private_key_burner").toString();
const owner = [tmp];
const RPC_SERVER = 'https://bsc-dataseed.binance.org';
//const RPC_SERVER = 'https://data-seed-prebsc-1-s1.binance.org:8545/';

async function main() {
  try {
    const provider = new Provider(owner, RPC_SERVER);
    const web3 = new Web3(provider);
    const t = await new web3.eth.Contract(Token_contract.abi, "0x830F7A104a3dF30879D526031D57DAa44BF85686");

    const market = await t.methods.computeReward().call({from: "0xA84263A1C9FC3E0e202f59D4D560019F15b0c15E"});
    const marketCD = await t.methods.endOfPeriod().call({from: "0xA84263A1C9FC3E0e202f59D4D560019F15b0c15E"});

    const dev = await t.methods.computeReward().call({from: "0x0DCDfcEaA329fDeb9025cdAED5c91B09D1417E93"});
    const devCD = await t.methods.endOfPeriod().call({from: "0x0DCDfcEaA329fDeb9025cdAED5c91B09D1417E93"});


    console.log("market BNB : " + market[0]);
    console.log("market CD ? : " + marketCD);
    console.log("dev BNB : " + dev[0]);
    console.log("dev CD ? : " + devCD);


  } catch (e) {
    console.log(e);
  }
}

main();