// hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },
  networks: {
    // ── Monad Mainnet ──────────────────────────────────────────────────────
    monad: {
      url:      process.env.MONAD_RPC_URL || "https://rpc.monad.xyz",
      chainId:  10143,
      accounts: process.env.DEPLOYER_PRIVATE_KEY
                  ? [process.env.DEPLOYER_PRIVATE_KEY]
                  : [],
      gasPrice: "auto",
    },
    // ── Monad Testnet ─────────────────────────────────────────────────────
    monadTestnet: {
      url:      "https://testnet-rpc.monad.xyz",
      chainId:  41454,
      accounts: process.env.DEPLOYER_PRIVATE_KEY
                  ? [process.env.DEPLOYER_PRIVATE_KEY]
                  : [],
    },
    // ── Local hardhat node (for testing) ──────────────────────────────────
    hardhat: {
      chainId: 31337,
    },
  },
  paths: {
    sources:   "./contracts",
    tests:     "./tests",
    cache:     "./cache",
    artifacts: "./artifacts",
  },
};
