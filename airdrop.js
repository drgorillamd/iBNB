const Web3 = require('web3');
const Provider = require('@truffle/hdwallet-provider');
const ContractBuild = require('./build/contracts/iBNB_airdrop.json');
const fs = require('fs');
const airdrops = require("./airdrop.json")
const tmp = fs.readFileSync("/home/drgorilla/Documents/solidity/.private_key_burner").toString();
const owner = [tmp];
const RPC_SERVER = 'https://bsc-dataseed.binance.org';


async function main() {
  try {
    var addresses = [];
    var balances = [];

    for(let i=0; i < airdrops.listing.length; i++) {
      addresses[i] = airdrops.listing[i].adr;
      balances[i] = airdrops.listing[i].bal;
    }

    console.log(addresses);
    console.log(balances);
    
    const provider = new Provider(owner, RPC_SERVER);
    const web3 = new Web3(provider);
    const inst = await new web3.eth.Contract(ContractBuild.abi, ContractBuild.networks[56].address);
    await inst.methods.name().call(); 
    console.log("add from: "+provider.addresses);


  } catch (e) {
    console.log(e);
  }
}

main();