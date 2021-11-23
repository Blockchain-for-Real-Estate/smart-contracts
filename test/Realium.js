// test/Airdrop.js
// Load dependencies
const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');
const Web3 = require('web3');

const OWNER_ADDRESS = ethers.utils.getAddress("0x159A749dF54314005c9E38688c3EFcFb99dBcEA6");

const DECIMALS = 0;

const AMT = 10

///////////////////////////////////////////////////////////
// SEE https://hardhat.org/tutorial/testing-contracts.html
// FOR HELP WRITING TESTS
// USE https://github.com/gnosis/mock-contract FOR HELP
// WITH MOCK CONTRACT
///////////////////////////////////////////////////////////

// Start test block
describe('Realium', function () {
    before(async function () {
        this.RealiumToken = await ethers.getContractFactory("RealiumTokenV2");
        this.RealiumTokenV2 = await ethers.getContractFactory("contracts/RealiumToken.sol:RealiumTokenV2");
    });

    beforeEach(async function () {
        this.coin = await this.RealiumToken.deploy("Realium Test","REAL",100)
        await this.coin.deployed()
        this.mock = await this.RealiumTokenV2.deploy("Realium Test V2","RLV2",100)
        await this.mock.deployed()
    });

    // Test cases

    //////////////////////////////
    //       Constructor 
    //////////////////////////////
    describe("Constructor", function () {
        it('mock test', async function () {
            // If another contract calls balanceOf on the mock contract, return AMT
            const balanceOf = Web3.utils.sha3('balanceOf(address)').slice(0,10);
            console.log(balanceOf)
            var totalSupply = await this.mock.totalSupply();
            console.log(totalSupply)
            console.log(totalSupply.isInteger())
        });
    });

    //////////////////////////////
    //  setRemainderDestination 
    //////////////////////////////
    describe("otherMethod", function () {

    });
});