import { } from "hardhat"

export interface networkConfigItem {
  name?: string, 
}

export interface networkConfigInfo {
  [key: number]: networkConfigItem
}

export const networkConfig: networkConfigInfo = {
  31337: {
    name:"localhost"
  },
  1337: {
    name:"hardhat"
  },
  11155111: {
    name:"sepolia"
  },
  97: {
    name:"bsc-testnet"
  },

}


export const developmentChains = ["hardhat", "localhost"];

