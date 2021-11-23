import { 
  Contract, 
  ContractFactory 
} from "ethers"
import { ethers } from "hardhat"

const main = async(): Promise<any> => {
  const RealiumToken: ContractFactory = await ethers.getContractFactory("RealiumTestToken")
  const realiumToken: Contract = await RealiumToken.deploy()
  console.log(realiumToken.interface.format('json'))

  await realiumToken.deployed()
  console.log(`Realium Token deployed to: ${realiumToken.address}`)
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error)
  process.exit(1)
})
