'use strict';
const truffleCost = require('truffle-cost');
const truffleAssert = require('truffle-assertions');
const time = require('./helper/timeshift');
const BN = require('bn.js');
require('chai').use(require('chai-bn')(BN)).should();

const Token = artifacts.require("iBNB");
const Presale = artifacts.require("iBNB_presale");
const routerContract = artifacts.require('IUniswapV2Router02');
const pairContract = artifacts.require('IUniswapV2Pair');
const routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
const devWallet = "0x000000000000000000000000000000000000dEaD";



contract("Presale-contract", accounts => {
        const deployer = accounts[0];
        const buying1BNB = accounts[1];
        const buying2BNB = accounts[2];

    describe("Setting the Scene", () => {

        it("Token to presale contract", async () => {
            const x = await Token.deployed();
            const sale = await Presale.deployed();
            const tot_supp = await x.totalSupply.call();
            await x.setCircuitBreaker(true, {from: accounts[0]});
            await x.transfer(sale.address, tot_supp, {from: accounts[0]});
            const new_bal = await x.balanceOf.call(sale.address);
            assert.equal(tot_supp, new_bal, "");
        });

        it("Add to whitelist", async() => { 
            var empty_addr = new Array(48);
            const empty_addr = 
        });

        it("Start presale", async () => {
            const x = await Token.deployed();
            const sale = await Presale.deployed();
            sale.
        });
    });

    describe("Presale", () => {

        it("Buy for 1BNB", async () => { 
        });

        it("Buy for 2BNB", async () => { 
        });

        it("Buy for 2+1BNB -> revert ?", async () => { 
        });

        it("Buy for 0.01BBN -> revert ?", async () => {
        });

        it("Buy from non whitelisted", async () => {
        });
    
    });

    describe("closing sale", () => {

        it("Closing", async () => { 
        });

        it("Claim for 1BNB", async () => { 
        });

        it("Claim for 2BNB", async () => { 
        });

        it("Claim non claimable -> revert ?", async () => {
        });

        it("Liquidity provided", async () => {
        });

    })




  });