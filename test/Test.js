const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers");
const { expect } = require("chai");

describe("Test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployTestTokenFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

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

    /** 
    const Holding = await ethers.getContractFactory("Holding");
    const holding = await Holding.deploy(vault.address, usdc.address);
    await holding.deployed();

    await vault.addHolding(1, holding.address);
    */

    return {usdc, token, vault, owner/**, holding*/, otherAccount};
  }

  describe("Deployment", function () {
    it("Mints 10 USDC to msg.sender upon deployment", async function () {
      const { usdc, owner} = await loadFixture(deployTestTokenFixture);
      const ownerBalance = await usdc.balanceOf(owner.address);
      expect(Number(ownerBalance)).to.equal(Number(10**7));
    });
  });

  describe("Deposit", function () {
    it("Owner can send 10 USDC to vault", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployTestTokenFixture);
      const ownerTesting = await usdc.balanceOf(owner.address);
      await usdc.connect(owner).approve(token.address, ownerTesting);
      await token.connect(owner).deposit(ownerTesting,owner.address);
      expect(Number(await vault.totalAssets())).to.equal(Number(10**7));
    });
    it("Owner gets 10 FET upon deposit", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployTestTokenFixture);
      const ownerTesting = await usdc.balanceOf(owner.address);
      await usdc.connect(owner).approve(token.address, ownerTesting);
      await token.connect(owner).deposit(ownerTesting,owner.address);
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(10**7));
    });
  });

  describe("Widthdraw", function () {
    it("Can widthdraw all FET", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployTestTokenFixture);
      const ownerTesting = await usdc.balanceOf(owner.address);
      await usdc.connect(owner).approve(token.address, ownerTesting);
      await token.connect(owner).deposit(ownerTesting,owner.address);
      await token.connect(owner).redeem(ownerTesting,owner.address,owner.address);
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(0));
      expect(Number(await usdc.balanceOf(owner.address))).to.equal(Number(10**7));
    });
    it("Can widthdraw half of FET", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployTestTokenFixture);
      const ownerTesting = await usdc.balanceOf(owner.address);
      await usdc.connect(owner).approve(token.address, ownerTesting);
      await token.connect(owner).deposit(ownerTesting,owner.address);
      await token.connect(owner).redeem((ownerTesting/2),owner.address,owner.address);
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number((10**6)*5));
      expect(Number(await usdc.balanceOf(owner.address))).to.equal(Number((10**6)*5));
    });
  });
});
