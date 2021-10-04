import { Contract, ContractFactory } from "ethers"
import { ethers } from "hardhat"

const main = async(): Promise<any> => {
  const GameItems: ContractFactory = await ethers.getContractFactory("GameItems")
  const gameItems: Contract = await GameItems.deploy()

  await gameItems.deployed()
  console.log(`Coin deployed to: ${gameItems.address}`)
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error)
  process.exit(1)
})