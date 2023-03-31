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

    //change all variable names eventually
    const FettiERC20 = await ethers.getContractFactory("FettiERC20");
    const token = await FettiERC20.deploy(usdc.address);
    await token.deployed();

    const Loaner = await ethers.getContractFactory("Loaner");
    const loaner = await Loaner.deploy(usdc.address);
    await loaner.deployed();

    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(usdc.address,token.address,loaner.address);
    await vault.deployed();

    await token.setVault(vault.address);

    //change all variable names eventually
    const EthPool = await ethers.getContractFactory("ethPool");
    const ethLoan = await EthPool.deploy(loaner.address, usdc.address, vault.address);
    await ethLoan.deployed();

    await loaner.connect(owner).addPool(ethLoan.address, 1,(10**12));
    await ethLoan.connect(owner).setLoanerId(1);

    const GNS = await ethers.getContractFactory("gns");
    const gns = await GNS.deploy();
    await gns.deployed();

    const GnsLoan = await ethers.getContractFactory("gnsPool");
    const gnsLoan = await GnsLoan.deploy(loaner.address, usdc.address, gns.address, vault.address);
    await gnsLoan.deployed();

    await loaner.connect(owner).addPool(gnsLoan.address, 2,(10**12));
    await gnsLoan.connect(owner).setLoanerId(2);

    return {usdc, token, vault, ethLoan, loaner, gns, gnsLoan, owner, otherAccount};
  }

  //await pause();
  //2 second pause
  const pause = async () => {
    await new Promise(resolve => setTimeout(resolve, 2000));
  };

  describe("Deployment of USDC", function () {

    it("Mints 10 dai to msg.sender upon deployment", async function () {
      const { usdc, owner} = await loadFixture(deployFixture);
      const ownerBalance = await usdc.balanceOf(owner.address);
      
      expect(Number(ownerBalance)).to.equal(Number(10**19));
    });

  });

  describe("FET mint", function () {

    it("Owner can send 10 USDC to vault", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance,owner.address);
      
      expect(Number(await vault.totalUsdc())).to.equal(Number(10**7));
    });

    it("Owner gets 10 FET upon deposit", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance, owner.address);
      
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(10**7));
    });

  });

  describe("FET Burn", function () {

    it("Can widthdraw all FET", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployFixture);
      const ownerBalance = 10**7;
      
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance,owner.address);
      await token.connect(owner).redeem(ownerBalance,owner.address,owner.address);
      
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(0));
      expect(Number(await usdc.balanceOf(owner.address))).to.equal(Number(10**19));
    });

    it("Can widthdraw half of FET", async function () {
      const { usdc, token, vault, owner} = await loadFixture(deployFixture);
      const ownerBalance = 10**7;
      
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance,owner.address);
      await token.connect(owner).redeem((ownerBalance/2),owner.address,owner.address);
      
      expect(Number(await token.maxWithdraw(owner.address))).to.equal(Number((10**6)*5));
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number((10**6)*5));
      expect(Number(await usdc.balanceOf(owner.address))).to.equal(Number((10**19)-((10**6)*5)));
    });

  });

  describe("Loaner & ethLoan Init", function () {

    it("Can send usdc from vault to loaner", async function () {      
      const { usdc, token, vault, loaner, owner} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance, owner.address);
      
      await vault.connect(owner).sendUsdcToLoaner(Number((10**7)/2));
      expect(Number(await vault.totalUsdc())).to.equal(Number(10**7));
      expect(Number(await vault.totalUsdcInVault())).to.equal(Number((10**7)/2));
      expect(Number(await loaner.totalUsdc())).to.equal(Number((10**7)/2));
    });

    it("Can Add Pool & Change Its Max", async function () {      
      const {ethLoan, loaner, owner} = await loadFixture(deployFixture);
      expect(Number(await loaner.getPoolMax(1))).to.equal(Number((10**12)));
      await loaner.connect(owner).setPoolMax(1,10);
      expect(Number(await loaner.getPoolMax(1))).to.equal(Number(10));
    });
  
  });

  describe("Loan Colateral", function () {

    it("Can deposit eth into the vault", async function () {
      const {ethLoan, otherAccount} = await loadFixture(deployFixture);
      await ethLoan.connect(otherAccount).depositColateralEth({ value: ethers.utils.parseEther("1") });
      expect(Number(await ethLoan.balanceOf(otherAccount.address))).to.equal(Number(1));
      expect(Number(await ethLoan.totalColateral(1))).to.equal(Number(10**18));
      expect(await ethLoan.ownerOf(1)).to.equal(otherAccount.address);
    });
 
    it("Can add eth to an outstanding loan", async function () {
      const {ethLoan, otherAccount} = await loadFixture(deployFixture);
      await ethLoan.connect(otherAccount).depositColateralEth({ value: ethers.utils.parseEther("1") });
      expect(Number(await ethLoan.balanceOf(otherAccount.address))).to.equal(Number(1));
      expect(Number(await ethLoan.totalColateral(1))).to.equal(Number(10**18));
      expect(await ethLoan.ownerOf(Number(1))).to.equal(otherAccount.address);
      await ethLoan.connect(otherAccount).addColateralEth(1, { value: ethers.utils.parseEther("1") });
      expect(Number(await ethLoan.totalColateral(1))).to.equal(Number(2*(10**18)));
    });

    it("Can close an outstanding loan, with timelock", async function () {
      const {ethLoan, otherAccount} = await loadFixture(deployFixture);
      await ethLoan.connect(otherAccount).depositColateralEth({ value: ethers.utils.parseEther("1") });
      expect(Number(await ethLoan.balanceOf(otherAccount.address))).to.equal(Number(1));
      expect(Number(await ethLoan.totalColateral(1))).to.equal(Number(10**18));
      expect(await ethLoan.ownerOf(Number(1))).to.equal(otherAccount.address);
      await pause();
      await ethLoan.connect(otherAccount).widthdrawColateralEth('0x0000000000000000000000000000000000000004',1);
      expect(Number(await ethers.provider.getBalance('0x0000000000000000000000000000000000000004'))).to.equal(Number(10**18));
      expect(await ethLoan.exists(1)).to.equal(false);
    });
    
  });

  describe("Borrowing USDC", function () {

    it("Can Borrow USDC", async function () {      
      const {usdc, token, vault, ethLoan, owner, otherAccount} = await loadFixture(deployFixture);
      const balance = 10**7;
      await usdc.connect(owner).approve(token.address, balance);
      await token.connect(owner).deposit(balance, owner.address);
        
      await vault.connect(owner).sendUsdcToLoaner(Number((10**7)/2));
      
      await ethLoan.connect(otherAccount).depositColateralEth({ value: ethers.utils.parseEther("1") });
      await ethLoan.connect(otherAccount).borrow(1, ((5*(10**6))-1), '0x0000000000000000000000000000000000000007');

      expect(Number(await usdc.balanceOf('0x0000000000000000000000000000000000000007'))).to.equal(Number((5*(10**6))-1));
      expect(Number(await ethLoan.getCurrHealth(1))).to.equal(Number(4999));
    });

    it("Can Repay USDC", async function () {      
      const {usdc, token, vault, ethLoan, owner, otherAccount} = await loadFixture(deployFixture);
      const balance = 10**7;
      await usdc.connect(owner).approve(token.address, balance);
      await token.connect(owner).deposit(balance, owner.address);
        
      await vault.connect(owner).sendUsdcToLoaner(Number((10**7)/2));
      
      await ethLoan.connect(otherAccount).depositColateralEth({ value: ethers.utils.parseEther("1") });
      await ethLoan.connect(otherAccount).borrow(1, (5*(10**6)), otherAccount.address);
      await usdc.connect(otherAccount).approve(ethLoan.address,(5*(10**6)));
      await ethLoan.connect(otherAccount).repayLoan(1,(5*(10**6)));
      expect(Number(await ethLoan.totalBorrow(1))).to.equal(0);
      expect(Number(await usdc.balanceOf(vault.address))).to.equal(Number(10**7));

    });
  
  });

  describe("All Basic Loan functionalities", function () {

    it("Can mint/burn fet, send usdc to loaner, deposit/add eth, borrow usdc, repay usdc, close loan", async function () {      
      const {usdc, token, vault, ethLoan, loaner, owner, otherAccount} = await loadFixture(deployFixture);
      
      const ownerBalance = 10**7;
      await usdc.connect(owner).approve(token.address, ownerBalance);
      await token.connect(owner).deposit(ownerBalance, owner.address);

      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(10**7));
      
      await vault.connect(owner).sendUsdcToLoaner(Number((10**7)/2));

      await ethLoan.connect(otherAccount).depositColateralEth({ value: ethers.utils.parseEther("1") });

      expect(Number(await ethLoan.totalColateral(1))).to.equal(Number(1*(10**18)));

      await ethLoan.connect(otherAccount).addColateralEth(1, { value: ethers.utils.parseEther("1") });

      expect(Number(await ethLoan.totalColateral(1))).to.equal(Number(2*(10**18)));

      await ethLoan.connect(otherAccount).borrow(1, 1000000, otherAccount.address);
      
      expect(Number(await token.totalAssets())).to.equal(Number(10**7));
      expect(Number(await loaner.poolFreeUsdc(1))).to.equal(Number(999999000000));
      expect(Number(await loaner.getPoolLoanAmount(1))).to.equal(Number(1000000));
      expect(Number(await loaner.totalLoanedOut())).to.equal(Number(1000000));
      expect(Number(await loaner.totalUsdc())).to.equal(Number((10**7)/2));
      expect(Number(await usdc.balanceOf(otherAccount.address))).to.equal(Number(1000000));
      expect(Number(await ethLoan.getCurrHealth(1))).to.equal(Number(500));


      await usdc.connect(otherAccount).approve(ethLoan.address,1000000);
      await ethLoan.connect(otherAccount).repayLoan(1,1000000);

      await pause();
      
      //only works for some addresses for some reason
      await ethLoan.connect(otherAccount).widthdrawColateralEth('0x0000000000000000000000000000000000000004',1);  
      expect(Number(await usdc.balanceOf(vault.address))).to.equal(Number(6*(10**6)));
      expect(Number(await loaner.totalUsdc())).to.equal(4*(10**6));
      expect(Number(await ethers.provider.getBalance('0x0000000000000000000000000000000000000004'))).to.equal(Number(2*(10**18)));
      expect(await ethLoan.exists(1)).to.equal(false);

      await token.connect(owner).redeem((6*(10**6)),owner.address,owner.address);
      
      expect(Number(await token.balanceOf(owner.address))).to.equal(Number(4*(10**6)));
      expect(Number(await usdc.balanceOf(owner.address))).to.equal(Number((10**19)-(4*(10**6))));
    });
  });

  describe("ERC20 Colateral Loan functionalities", function () {

    it("GNS inits", async function () {      
      const {gns, owner} = await loadFixture(deployFixture);
      expect(Number(await gns.balanceOf(owner.address))).to.equal(Number(10**19));
    });

    it("Init colateral", async function () {      
      const {gns, gnsLoan, owner} = await loadFixture(deployFixture);
      await gns.connect(owner).approve(gnsLoan.address,50);
      await gnsLoan.connect(owner).depositColateral(owner.address, 50);
      expect(Number(await gnsLoan.balanceOf(owner.address))).to.equal(Number(1));
      expect(Number(await gnsLoan.totalColateral(1))).to.equal(Number(50));
    });

    it("Add colateral", async function () {      
      const {gns, gnsLoan, owner} = await loadFixture(deployFixture);
      await gns.connect(owner).approve(gnsLoan.address,50);
      await gnsLoan.connect(owner).depositColateral(owner.address, 50);
      expect(Number(await gnsLoan.balanceOf(owner.address))).to.equal(Number(1));
      expect(Number(await gnsLoan.totalColateral(1))).to.equal(Number(50));
      await gnsLoan.changeDaiRatio(Number(10**7));
      await gns.connect(owner).approve(gnsLoan.address,150);
      await gnsLoan.connect(owner).addColateral(1, 150);
      expect(Number(await gnsLoan.totalColateral(1))).to.equal(Number(200));
      expect(Number(await gnsLoan.getDaiRatio(1))).to.equal(Number(0));
      expect(Number(await gnsLoan.getStakedGns(1))).to.equal(Number(50));
    });


    //add widthdrawls testing and expectations
    it("Widthdraw colateral", async function () {      
      const {gns, gnsLoan, owner} = await loadFixture(deployFixture);
      await gns.connect(owner).approve(gnsLoan.address,50);
      await gnsLoan.connect(owner).depositColateral(owner.address, 50);
      expect(Number(await gnsLoan.balanceOf(owner.address))).to.equal(Number(1));
      expect(Number(await gnsLoan.totalColateral(1))).to.equal(Number(50));
      await gnsLoan.changeDaiRatio(Number(10**7));
      await gns.connect(owner).approve(gnsLoan.address,150);
      await gnsLoan.connect(owner).addColateral(1, 150);
      expect(Number(await gnsLoan.totalColateral(1))).to.equal(Number(200));
      expect(Number(await gnsLoan.getDaiRatio(1))).to.equal(Number(0));
      expect(Number(await gnsLoan.getStakedGns(1))).to.equal(Number(50));
      await gnsLoan.connect(owner).widthdrawColateral(owner.address, 1);
      expect(Number(await gns.balanceOf(owner.address))).to.equal(10**19);
      expect(Number(await gnsLoan.balanceOf(owner.address))).to.equal(0);
    });

    

  



  });

  describe("Liquidations", function () {

    it("WIP", async function () {      
      const {usdc, token, vault, gns, gnsLoan, owner} = await loadFixture(deployFixture);
      
      const balance = 10**7;
      await usdc.connect(owner).approve(token.address, balance);
      await token.connect(owner).deposit(balance, owner.address);
        
      await vault.connect(owner).sendUsdcToLoaner(Number((10**7)/2));

      await gns.connect(owner).approve(gnsLoan.address,200);
      await gnsLoan.connect(owner).depositColateral(owner.address, 200);
      expect(Number(await gnsLoan.balanceOf(owner.address))).to.equal(Number(1));
      expect(Number(await gnsLoan.totalColateral(1))).to.equal(Number(200));
      expect(Number(await gnsLoan.getDaiRatio(1))).to.equal(Number(0));

      await gnsLoan.connect(owner).borrow(1, (10), '0x0000000000000000000000000000000000000007');

      expect(Number(await usdc.balanceOf('0x0000000000000000000000000000000000000007'))).to.equal(Number(10));
      expect(Number(await gnsLoan.totalBorrow(1))).to.equal(10);
      expect(Number(await gnsLoan.totalColateral(1))).to.equal(200);
      expect(Number(await gnsLoan.getCurrHealth(1))).to.equal(Number(7142857142857142));

      await gnsLoan.connect(owner).changeGnsPrice(Number(83333));
      expect(Number(await gnsLoan.getCurrHealth(1))).to.greaterThan(Number(6e17));
      expect(Number(await gnsLoan.getNewLiqHealth(1, 8))).to.greaterThan(Number(6e17));



    });

  });

  
});
