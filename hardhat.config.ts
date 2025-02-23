import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "dotenv/config";



const RPC_ENDPOINT_SEPOLIA_NETWORK = process.env.RPC_URL_SEPOLIA_NETWORK;
const PRIVATE_KEY_ACCOUNT_SEPOLIA = process.env.PRIVATE_KEY_SEPOLIA_NETWORK??"0x";
const API_KEY_ETHERSCAN = process.env.ETHERSCAN_API_KEY;

//BNB Testnet
const RPC_ENDPOINT_BNB_TEST_NETWORK = process.env.RPC_URL_BNB_Test_NETWORK;

// Mainnet
const PRIVATE_KEY_PRODUCTION = process.env.PRIVATE_KEY_PRODUCTION??"";
const RPC_ENDPOINT_BNB_NETWORK = process.env.RPC_URL_BNB_NETWORK;


const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.26",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337,
      saveDeployments:true
    },
    hardhatLocal: {
      url: "http://127.0.0.1:8545/",
      chainId: 1337,
    },
    sepolia: {
      chainId: 11155111,
      url: RPC_ENDPOINT_SEPOLIA_NETWORK,
      accounts: [PRIVATE_KEY_ACCOUNT_SEPOLIA],
    },
    bnbTestnet: {
      chainId: 97,
      url: RPC_ENDPOINT_BNB_TEST_NETWORK,
      accounts: [PRIVATE_KEY_ACCOUNT_SEPOLIA],
    },
    bnb: {
      chainId: 97,
      url: RPC_ENDPOINT_BNB_NETWORK,
      accounts: [PRIVATE_KEY_PRODUCTION],
    },

  },
  etherscan: {
    apiKey: API_KEY_ETHERSCAN,
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    token: "ETH",
    outputFile: "gas-repoter.txt",
    noColors: true,
  },
  sourcify: {
    enabled:true
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },

};

export default config;
