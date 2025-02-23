import { ethers, network } from "hardhat";
import "dotenv/config";
import * as artifacts from "../artifacts/contracts/SmartEaglrMatrix_V2.sol/SmartEaglrMatrix.json"
import * as inputFile from "../data/Eagles.users.json";


async function main() {

  // const eagleContract = await ethers.deployContract("SmartEaglrMatrix", [], {});

  const provider = new ethers.JsonRpcProvider(process.env.RPC_URL_BNB_Test_NETWORK);
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY_SEPOLIA_NETWORK as string, provider);

  const contractAddress = process.env.CONTRACT_ADDRESS_BNB_TESTNET as string;

  const abi = artifacts.abi;

  const contract = new ethers.Contract(contractAddress, abi, signer);

  console.log("Fetching USDT Address from contract...");
  const usdt = await contract.USDTAddress();
  console.log("USDT Address:", usdt);


  
  //last-id fetched 
  const lastIdStored = await contract.lastUserid();
  console.log("lastIdStored : ", lastIdStored)

  let _refrers: string[] = [];
  let  _users: string[] = [];
  let  levelX1s: number[] = [];
  let  levelX2s: number[] = [];
  let  _usdtRecieveds: string[] = [];


  //Fetch data 30 records:
  const startIndex = +lastIdStored.toString() - 1;
  for (let i = 0; i < 100; i++){
    const userData = inputFile[startIndex + i];
    console.log(`Recode : ${startIndex + i}`)

    _refrers.push(userData.referrer);
    _users.push(userData.Personal);

    levelX1s.push(userData.currentX1Level);
    levelX2s.push(userData.currentX2Level);

    _usdtRecieveds.push(userData.totalUSDTReceived.$numberDecimal);

  }

  const trx = await contract.transferData(_refrers, _users, levelX1s, levelX2s, _usdtRecieveds);
  

  console.log(`trx: recorde stored from ${startIndex+1}: to ${startIndex+100}`, trx.hash);

  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
