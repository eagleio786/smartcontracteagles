import { expect } from "chai";
import { deployments, ethers, getNamedAccounts } from "hardhat";
import { SignerWithAddress} from "@nomicfoundation/hardhat-ethers/signers";

describe("SmartEaglrMatrix", function () {
  let accounts: SignerWithAddress[];
  let tokenContract:any;

  beforeEach(async () => {
    accounts = await ethers.getSigners();

    const contractName = "SmartEaglrMatrix"
    const tags = ["SmartEaglrMatrix"];

    const allDeployments = await deployments.fixture(tags);
    tokenContract = await ethers.getContractAt(contractName, allDeployments[contractName].address);
  })

  describe("Initialize Values", async () => {
    
    // it("Token Name should be set",async () => {
    //   expect(await tokenContract.name()).to.be.equal("TokenContract")      
    // })

    // it("Token Symbol should be set",async () => {
    //   expect(await tokenContract.symbol()).to.be.equal("TOKEN")      
    // })

    // it("Token Supply should be 200_000_000", async () => {
    //   expect(await tokenContract.totalSupply()).to.be.equal(ethers.parseEther("200000000"))      
    // })

  })

});
