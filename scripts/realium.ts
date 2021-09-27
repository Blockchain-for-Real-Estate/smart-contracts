import { Contract, ContractFactory } from "ethers"
import { ethers } from "hardhat"

const main = async(): Promise<any> => {
  const RealiumToken: ContractFactory = await ethers.getContractFactory("RealiumToken")
  const realiumToken: Contract = await Coin.deploy()

  await realiumToken.deployed()
  console.log(`Coin deployed to: ${realiumToken.address}`)
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error)
  process.exit(1)
})