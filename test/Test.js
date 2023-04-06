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

    const Dai = await ethers.getContractFactory("Dai");
    const dai = await Dai.deploy();
    await dai.deployed();

    const Fetti = await ethers.getContractFactory("FettiERC20");
    const fetti = await Fetti.deploy(dai.address);
    await fetti.deployed();

    const Loaner = await ethers.getContractFactory("Loaner");
    const loaner = await Loaner.deploy(dai.address);
    await loaner.deployed();

    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(dai.address,fetti.address,loaner.address);
    await vault.deployed();

    await fetti.setVault(vault.address);

    const GNS = await ethers.getContractFactory("gns");
    const gns = await GNS.deploy();
    await gns.deployed();

    const GnsPool = await ethers.getContractFactory("gnsPool");
    const gnsPool = await GnsPool.deploy(loaner.address, dai.address, gns.address, vault.address);
    await gnsPool.deployed();

    await loaner.connect(owner).addPool(gnsPool.address, (10**12));

    return {dai,fetti,vault,loaner, gns, gnsPool, owner,otherAccount};
  }

  //await pause();
  //2 second pause
  const pause = async () => {
    await new Promise(resolve => setTimeout(resolve, 2000));
  };

  describe("Basics", function () {

    it("Dai Deployment", async function () {
      const {dai,owner} = await loadFixture(deployFixture);

      expect(Number(await dai.balanceOf(owner.address))).to.equal(Number(1e19));
    });
    it("FET Mint & Burn", async function () {
      const {dai,fetti,owner} = await loadFixture(deployFixture);

      const ownerBalance = 10**7;
      await dai.connect(owner).approve(fetti.address,ownerBalance);
      await fetti.connect(owner).deposit(ownerBalance,owner.address);
      expect(Number(await fetti.totalAssets())).to.equal(Number(1e7));
      expect(Number(await fetti.totalDaiInVault())).to.equal(Number(1e7));
      expect(Number(await fetti.maxRedeem(owner.address))).to.equal(Number(1e7));
      expect(Number(await fetti.maxWithdraw(owner.address))).to.equal(Number(1e7));

      await fetti.connect(owner).redeem(ownerBalance, owner.address, owner.address);
      expect(Number(await fetti.totalAssets())).to.equal(Number(0));
      expect(Number(await fetti.totalDaiInVault())).to.equal(Number(0));
      expect(Number(await fetti.maxRedeem(owner.address))).to.equal(Number(0));
      expect(Number(await fetti.maxWithdraw(owner.address))).to.equal(Number(0));
    });

    it("Can send usdc from vault to loaner", async function () {      
      const { dai, fetti, vault, loaner, owner} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await dai.connect(owner).approve(fetti.address, ownerBalance);
      await fetti.connect(owner).deposit(ownerBalance, owner.address);
      await vault.connect(owner).sendDaiToLoaner(Number((10**7)/2));
      expect(Number(await vault.totalDai())).to.equal(Number(10**7));
      expect(Number(await vault.totalDaiInVault())).to.equal(Number((10**7)/2));
      expect(Number(await loaner.totalDai())).to.equal(Number((10**7)/2));
    });

    it("Adding & withdrawing collateral", async function () {      
      const {dai,fetti,vault,loaner, gns, gnsPool, owner,otherAccount} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await gns.connect(owner).approve(gnsPool.address, ownerBalance);
      await gnsPool.connect(owner).depositColateral(owner.address,ownerBalance);
      expect(Number(await gnsPool.totalColateral(1))).to.equal(ownerBalance);
      
      await pause();
      await gnsPool.connect(owner).widthdrawColateral(owner.address,1);
      expect(Number(await gnsPool.balanceOf(owner.address))).to.equal(0);
      expect(Number(await gns.balanceOf(gnsPool.address))).to.equal(0);
      expect(Number(await gns.balanceOf(owner.address))).to.equal(Number(1e19));
    });

    it("Can borrow and repay dai", async function () {      
      const {dai,fetti,vault,loaner,gns,gnsPool,owner} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await dai.connect(owner).approve(fetti.address, ownerBalance);
      await fetti.connect(owner).deposit(ownerBalance, owner.address);
      
      await vault.connect(owner).sendDaiToLoaner(Number((10**7)/2));
      expect(Number(await vault.totalDai())).to.equal(Number(10**7));
      expect(Number(await vault.totalDaiInVault())).to.equal(Number((10**7)/2));
      expect(Number(await loaner.poolFreeDai())).to.equal(Number((10**7)/2));
    
      await gns.connect(owner).approve(gnsPool.address, ownerBalance);
      await gnsPool.connect(owner).depositColateral(owner.address,ownerBalance);
      expect(Number(await gnsPool.totalColateral(1))).to.equal(ownerBalance);

      await gnsPool.connect(owner).borrow(1,200,'0x0000000000000000000000000000000000000007');
      expect(Number(await dai.balanceOf('0x0000000000000000000000000000000000000007'))).to.equal(200);
      expect(Number(await loaner.totalDai())).to.equal(Number((10**7)/2));
      expect(Number(await loaner.totalDaiInLoaner())).to.equal(Number(((10**7)/2)-200));
      expect(Number(await loaner.totalLoanedOut())).to.equal(Number(200));
      expect(Number(await loaner.poolFreeDai())).to.equal(Number(((10**7)/2)-200));

      await dai.connect(owner).approve(gnsPool.address,200);
      await gnsPool.connect(owner).repayLoan(1,200);
      //dai sent to vault not loaner
      expect(Number(await loaner.totalDai())).to.equal(Number((10**7)/2)-200);
      expect(Number(await loaner.totalDaiInLoaner())).to.equal(Number(((10**7)/2)-200));
      expect(Number(await loaner.totalLoanedOut())).to.equal(Number(0));
      expect(Number(await loaner.poolFreeDai())).to.equal(Number(((10**7)/2)-200));
      expect(Number(await vault.totalDaiInVault())).to.equal(((1e7)/2)+200);
      expect(Number(await vault.totalDai())).to.equal(Number(1e7));

    });



  });
});
