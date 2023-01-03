const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
//const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployTestTokenFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const TestingERC20 = await ethers.getContractFactory("TestingERC20");
    const testingERC20 = await TestingERC20.deploy("Testing", "TST");
    await testingERC20.deployed();

    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy(testingERC20.address,"Vault","VLT");
    await token.deployed();

    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(testingERC20.address,token.address);
    await vault.deployed();

    await token.setVault(vault.address);
    return { testingERC20, token, vault, owner};
  }
 
  describe("Deployment", function () {
    it("Mints 10 TST to msg.sender upon deployment", async function () {
      const { testingERC20, owner} = await loadFixture(deployTestTokenFixture);
      const ownerBalance = await testingERC20.balanceOf(owner.address);
      expect(Number(ownerBalance)).to.equal(Number(10**7));
    });
  });

  describe("Deposit", function () {
    it("Owner can send 10 TST to vault", async function () {
      const { testingERC20, token, vault, owner} = await loadFixture(deployTestTokenFixture);
      const ownerTesting = await testingERC20.balanceOf(owner.address);
      await testingERC20.connect(owner).approve(token.address, ownerTesting);
      await token.connect(owner).deposit(ownerTesting,owner.address);
      expect(Number(await vault.totalAssets())).to.equal(Number(10**7));
    });
    it("Owner gets 10 VLT upon deposit", async function () {
      const { testingERC20, token, vault, owner} = await loadFixture(deployTestTokenFixture);
      const ownerTesting = await testingERC20.balanceOf(owner.address);
      await testingERC20.connect(owner).approve(token.address, ownerTesting);
      await token.connect(owner).deposit(ownerTesting,owner.address);
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(10**7));
    });
  });

  describe("Widthdraw", function () {
    it("Can widthdraw all of funds", async function () {
      const { testingERC20, token, vault, owner} = await loadFixture(deployTestTokenFixture);
      const ownerTesting = await testingERC20.balanceOf(owner.address);
      await testingERC20.connect(owner).approve(token.address, ownerTesting);
      await token.connect(owner).deposit(ownerTesting,owner.address);
      await token.connect(owner).redeem(ownerTesting,owner.address,owner.address);
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(0));
      expect(Number(await testingERC20.balanceOf(owner.address))).to.equal(Number(10**7));
    });
    it("Can widthdraw half of funds", async function () {
      const { testingERC20, token, vault, owner} = await loadFixture(deployTestTokenFixture);
      const ownerTesting = await testingERC20.balanceOf(owner.address);
      await testingERC20.connect(owner).approve(token.address, ownerTesting);
      await token.connect(owner).deposit(ownerTesting,owner.address);
      await token.connect(owner).redeem((ownerTesting/2),owner.address,owner.address);
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number((10**6)*5));
      expect(Number(await testingERC20.balanceOf(owner.address))).to.equal(Number((10**6)*5));
    });
  });
});
