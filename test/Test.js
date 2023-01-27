const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Test", function () {

  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const USDC = await ethers.getContractFactory("USDC");
    const usdc = await USDC.deploy();
    await usdc.deployed();

    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy(usdc.address);
    await token.deployed();

    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(usdc.address,token.address);
    await vault.deployed();

    await token.setVault(vault.address);

    return {usdc, token, vault, owner, otherAccount};
  }

  describe("Deployment of USDC", function () {

    it("Mints 10 USDC to msg.sender upon deployment", async function () {
      const { usdc, owner} = await loadFixture(deployFixture);
      const ownerBalance = await usdc.balanceOf(owner.address);
      
      expect(Number(ownerBalance)).to.equal(Number(10**7));
    });

  });

  describe("Deposit as a Creditor", function () {

    it("Owner can send 10 USDC to vault", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance,owner.address);
      
      expect(Number(await vault.totalAssets())).to.equal(Number(10**7));
    });

    it("Owner gets 10 FET upon deposit", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance,owner.address);
      
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(10**7));
    });

  });

  describe("Widthdraw as a creditor", function () {

    it("Can widthdraw all FET", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployFixture);
      const ownerBalance = 10**7;
      
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance,owner.address);
      await token.connect(owner).redeem(ownerBalance,owner.address,owner.address);
      
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(0));
      expect(Number(await usdc.balanceOf(owner.address))).to.equal(Number(10**7));
    });

    it("Can widthdraw half of FET", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployFixture);
      const ownerBalance = 10**7;
      
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance,owner.address);
      await token.connect(owner).redeem((ownerBalance/2),owner.address,owner.address);
      
      expect(Number(await token.maxWithdraw(owner.address))).to.equal(Number((10**6)*5));
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number((10**6)*5));
      expect(Number(await usdc.balanceOf(owner.address))).to.equal(Number((10**6)*5));
    });

  });

  /**
  describe("Loan", function () {

    it("Can deposit eth into the vault", async function () {
      const {loan, owner} = await loadFixture(deployLoanFixture);
    });

  });
  */
});
