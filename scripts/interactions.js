// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();
const fs = require("fs");
const { gnsPool_ABI } = require("../artifacts/contracts/gnsPool.sol/gnsPool.json");

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {

  const provider = new ethers.providers.JsonRpcProvider('https://polygon-mainnet.g.alchemy.com/v2/4V5_YRAkOspP8Qt77tMI5nldABfga1dC');
  const [owner] = await ethers.getSigners();

  const GnsPool = await ethers.getContractFactory("gnsPool");

  console.log("creating local contract");
  const tokenAddress = '0x7922EA3888Bc9E033C32091c907075e34FF2a397';
  const tokenContract = new ethers.Contract(tokenAddress, gnsPool_ABI.abi, provider);
  console.log("created local contract. approving");
  
  const x = await gnsPool.currGnsPrice();
  console.log("gns price: ", x);
  const y = await gnsPool.totalColateral(Number(1));
  console.log("loan colateral: ", y);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});