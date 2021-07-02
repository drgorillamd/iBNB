const Web3 = require('web3');
const Provider = require('@truffle/hdwallet-provider');
const Airdrop_contract = require('./build/contracts/iBNB_airdrop.json');
const Token_contract = require('./build/contracts/iBNB.json')
const fs = require('fs');
const airdrops = require("./airdrop.json")
//const airdrops = require("./TEST airdrop TEST.json")



//const tmp = fs.readFileSync("/home/drgorilla/Documents/solidity/.private_key_testnet").toString();
const tmp = fs.readFileSync("/home/drgorilla/Documents/solidity/.private_key_burner").toString();
const owner = [tmp];
const RPC_SERVER = 'https://bsc-dataseed.binance.org';
//const RPC_SERVER = 'https://data-seed-prebsc-1-s1.binance.org:8545/';

async function main() {
  try {
    var addresses = [];
    var balances = [];

    for(let i=0; i < airdrops.listing.length; i++) {
      addresses[i] = airdrops.listing[i].adr;
      balances[i] = airdrops.listing[i].bal;
    }
    
    const provider = new Provider(owner, RPC_SERVER);
    const web3 = new Web3(provider);

    const a = await new web3.eth.Contract(Airdrop_contract.abi, "0xfcDBF3788AbDc582C903844D384290d31e6F550d");
    const t = await new web3.eth.Contract(Token_contract.abi, "0x830F7A104a3dF30879D526031D57DAa44BF85686");

    //const a = await new web3.eth.Contract(Airdrop_contract.abi, Airdrop_contract.networks[97].address);
    //const t = await new web3.eth.Contract(Token_contract.abi, Token_contract.networks[97].address);

    await t.methods.approve(a.options.address, '5'+'0'.repeat(25)).send({from: provider.addresses[0]});

    await a.methods.send_airdrop(addresses, balances).send({from: provider.addresses[0]}); 

  } catch (e) {
    console.log(e);
  }
}

main();