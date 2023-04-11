// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();
const fs = require("fs");
const { ERC20_ABI } = require("./ERC20_ABI");

async function main() {

  // Contracts are deployed using the first signer/account by default
  const [owner] = await ethers.getSigners();

  const Fetti = await ethers.getContractFactory("FettiERC20");
  const fetti = await Fetti.deploy();
  await fetti.deployed();
  console.log("fetti address: ",fetti.address);

  const Loaner = await ethers.getContractFactory("Loaner");
  const loaner = await Loaner.deploy();
  await loaner.deployed();
  console.log("loaner address: ",loaner.address);

  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(fetti.address,loaner.address);
  await vault.deployed();
  console.log("vault address: ",vault.address);

  await fetti.setVault(vault.address);

  const GnsPool = await ethers.getContractFactory("gnsPool");
  const gnsPool = await GnsPool.deploy(loaner.address, vault.address);
  await gnsPool.deployed();
  console.log("gnsPool address: ", gnsPool.address);

  await loaner.connect(owner).addPool(gnsPool.address, Number(10**12));

  console.log("creating local contract");
  const tokenAddress = '0xE5417Af564e4bFDA1c483642db72007871397896';
  const tokenContract = new ethers.Contract(tokenAddress, ERC20_ABI, owner);
  console.log("created local contract. approving");
  const approveTx = await tokenContract.connect(owner).approve(gnsPool.address, Number(100));
  await approveTx.wait();
  console.log("approved");



  await gnsPool.connect(owner).depositColateral(owner.address, Number(100));
  const x = await gnsPool.currGnsPrice();
  console.log("gns price: ", x);
  const y = await gnsPool.totalColateral(Number(1));
  console.log("loan colateral: ", y);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});