import {
  BigNumber,
  Contract
} from "ethers"
import { ethers } from "hardhat"

const coinName: string = "SimpleRestrictedToken"
const coinAddr: string = "0x1b165F88e8F93b54fFA4D83C8A560E408bE17911"
const walletAddress: string = "0xdab9aa993035e4303c58b13441c70c26d70ab3e6"

const main = async (): Promise<any> => {
  const contract: Contract = await ethers.getContractAt(coinName, coinAddr)
  const contractAddress: string = contract.address
  console.log(`Address: ${contractAddress}`)

  const sender: string = await contract.getSender()
  console.log(`Sender: ${sender}`)

  const name: string = await contract.name()
  console.log(`Name: ${name}`)

  const symbol: string = await contract.symbol()
  console.log(`Symbol: ${symbol}`)

  const decimals: string = await contract.decimals()
  console.log(`Decimals: ${decimals}`)

  const balance: BigNumber = await contract.balanceOf(walletAddress)
  console.log(`Balance of ${walletAddress}: ${balance.toString()}`)

  let totalSupply: BigNumber = await contract.totalSupply()
  console.log(`Total supply: ${totalSupply.toString()}`)

  console.log(`-----MINTING-----`)
  await contract.mint(walletAddress, totalSupply)

  totalSupply = await contract.totalSupply()
  console.log(`Total supply: ${totalSupply.toString()}`)

  console.log(`-----BURNING-----`)
  await contract.burn(walletAddress, totalSupply)

  totalSupply = await contract.totalSupply()
  console.log(`Total supply: ${totalSupply.toString()}`)

  const tx = await contract.transfer(walletAddress, balance)
  console.log("--TX--")
  console.log(tx)

  const txReceipt = await tx.wait()
  console.log("--TX RECEIPT--")
  console.log(txReceipt)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })