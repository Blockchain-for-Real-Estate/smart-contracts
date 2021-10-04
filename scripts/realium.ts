import { Contract, ContractFactory } from "ethers"
import { ethers } from "hardhat"

const main = async(): Promise<any> => {
  const RealiumToken: ContractFactory = await ethers.getContractFactory("RealiumTokenV2")
  const realiumToken: Contract = await RealiumToken.deploy()

  await realiumToken.deployed()
  console.log(`Coin deployed to: ${realiumToken.address}`)
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error)
  process.exit(1)
})