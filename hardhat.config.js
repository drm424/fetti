require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-ethers");
require('dotenv').config();


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    polygon: {
      url: process.env.API_KEY,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 137,
      gasPrice: 150e9
    },
  },
};
