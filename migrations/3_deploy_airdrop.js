const Migrations = artifacts.require("Migrations");
const iBNB = artifacts.require("iBNB");
const iBNB = artifacts.require("iBNB_airdrop");

module.exports = function(deployer) {
    deployer.deploy(iBNB_airdrop, iBNB.address);
};
