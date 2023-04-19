// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
//take this out if the script doesn't work
const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {

  // Contracts are deployed using the first signer/account by default
  const provider = new ethers.providers.JsonRpcProvider(process.env.API_KEY);
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
  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});