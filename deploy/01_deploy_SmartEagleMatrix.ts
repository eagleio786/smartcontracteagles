import {DeployFunction} from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { developmentChains, networkConfig } from "../helper-hardhat-config";
import verify from "../scripts/verify";



const deployFun:DeployFunction = async (hre:HardhatRuntimeEnvironment) => {

    const { deployments, getNamedAccounts, network, ethers } = hre;
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = network.config.chainId!;

    const Constructorargs: any = [];
    const Initializeargs: any = [];
    
    const usdtAddress: string = "0x55d398326f99059fF775485246999027B3197955";
    Initializeargs[0] = usdtAddress;

    const SmartEaglrMatrixContract = await deploy("SmartEaglrMatrix", {
        from: deployer,
        args: Constructorargs,
        waitConfirmations: 1,
        proxy: {
            execute: {
                init: {
                    methodName: "initialize",
                    args:Initializeargs,
                }
            },
            proxyContract:"OpenZeppelinTransparentProxy"
        }
    })

    const SmartEaglrMatrixContractContractAddress = SmartEaglrMatrixContract.address;
    log(`SmartEaglrMatrix Contract deployed at ${SmartEaglrMatrixContractContractAddress}`);

    

    //Not a developer-chain
    if (!developmentChains.includes(networkConfig[chainId].name!)) {
        verify(SmartEaglrMatrixContractContractAddress, Constructorargs)
    }
}

export default deployFun;
deployFun.tags = ["SmartEaglrMatrix"]