// test/Airdrop.js
// Load dependencies
const { expect } = require('chai');
const { assert } = require('console');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');
const Web3 = require('web3');

//IS THIS WHO KNOWS THE CONTRACT?
const OWNER_ADDRESS = ethers.utils.getAddress("0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC");
//0x13480b98ee09dBcBbf775Be7eBC29Ce097fD3287
//Account: 0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027
//0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC

// const DECIMALS = 2;

const AMT = 150

///////////////////////////////////////////////////////////
// SEE https://hardhat.org/tutorial/testing-contracts.html
// FOR HELP WRITING TESTS
// USE https://github.com/gnosis/mock-contract FOR HELP
// WITH MOCK CONTRACT
///////////////////////////////////////////////////////////

// Start test block
describe('RealiumTokenV2', function () {
    before(async function () {
        this.RealiumToken = await ethers.getContractFactory("RealiumTokenV2");
        // this.MockContract = await ethers.getContractFactory("contracts/RealiumTokenV2.sol:RealiumTokenV2");
    });

    beforeEach(async function () {
        this.realiumToken = await this.RealiumToken.deploy()
        await this.realiumToken.deployed()
        console.log(`Token deployed to: ${this.realiumToken.address}`)
        // this.mock = await this.MockContract.deploy()
        // await this.mock.deployed()
    });

    // Test cases

    //////////////////////////////
    //       Constructor 
    //////////////////////////////
    describe("Constructor", function () {
        it('mock test', async function () {
            console.log(this.realiumToken);
            const ADMIN_ROLE = await this.realiumToken.DEFAULT_ADMIN_ROLE();
            console.log(`ADMIN ROLE: ${ADMIN_ROLE}`)
            const hasAdminRole = await this.realiumToken.hasRole(ADMIN_ROLE, OWNER_ADDRESS);
            console.log(hasAdminRole);
            const creator = await this.realiumToken.creator();
            console.log(creator)
            let accountBal = await this.realiumToken.balanceOf(creator,0);
            console.log(accountBal)
            // console.log(await this.realiumToken.hasRole(ADMIN_ROLE, OWNER_ADDRESS));
            // // console.log(await this.realiumToken.hasRole(this.realiumToken.address));
            // console.log(await this.realiumToken.TESTPROPERTY1())
            // let accounts = await ethers.provider.listAccounts();
            // let accountBal = await this.realiumToken.balanceOf(this.realiumToken.address,0);
            // console.log(`${this.realiumToken.address}: ${accountBal}`)
            // let accountBal2 = await this.realiumToken.balanceOf(OWNER_ADDRESS,0);
            // console.log(`${OWNER_ADDRESS}: ${accountBal2}`)
            // await accounts.forEach(async account => {
            //     const balance = await this.realiumToken.balanceOf(account, 0)
            //     console.log(`${account}: ${balance}`)
            // });
            // console.log(accounts[0])
            // // If another contract calls balanceOf on the mock contract, return AMT
            // // const balanceOf = Web3.utils.sha3('balanceOf(address)').slice(0,10);
            // const balanceOf = await this.realiumToken.balanceOf(accounts[0], 0);
            // console.log(balanceOf);
            // const numTokens = BigNumber.from(balanceOf);
            // console.log(numTokens);
            // // const numTokens1 = balanceOf.ToNumber();
            // // console.log(numTokens1);
            // console.log(balanceOf.toString())
            // assert(balanceOf==10);
            // await this.mock.givenMethodReturnUint(balanceOf, AMT);
        });
    });

    //////////////////////////////
    //  setRemainderDestination 
    //////////////////////////////
    describe("otherMethod", function () {

    });
});