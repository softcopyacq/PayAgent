// scripts/deploy.js
// PayAgent — Monad Mainnet Deployment Script
// Run: node scripts/deploy.js

require("dotenv").config();
const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

// ── Config ────────────────────────────────────────────────────────────────────
const MONAD_RPC   = process.env.MONAD_RPC_URL || "https://rpc.monad.xyz";
const PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY;
const ORACLE_ADDR = process.env.COMPLIANCE_ORACLE_ADDRESS;

// Compiled ABI + bytecode (run: npx hardhat compile first)
// For demo purposes, we load from artifacts
const ARTIFACT_PATH = path.join(__dirname, "../artifacts/contracts/PayAgentCompliance.sol/PayAgentCompliance.json");

async function main() {
  console.log("═══════════════════════════════════════════════");
  console.log("  PayAgent — Monad Mainnet Deployment");
  console.log("  NormaNova · Cleanverse Build 2026");
  console.log("═══════════════════════════════════════════════\n");

  if (!PRIVATE_KEY) throw new Error("DEPLOYER_PRIVATE_KEY not set in .env");
  if (!ORACLE_ADDR) throw new Error("COMPLIANCE_ORACLE_ADDRESS not set in .env");

  // ── Connect to Monad ───────────────────────────────────────────────────────
  const provider = new ethers.JsonRpcProvider(MONAD_RPC);
  const wallet   = new ethers.Wallet(PRIVATE_KEY, provider);

  console.log(`📡  Connected to: ${MONAD_RPC}`);
  console.log(`👛  Deployer:     ${wallet.address}`);

  const balance = await provider.getBalance(wallet.address);
  console.log(`💰  Balance:      ${ethers.formatEther(balance)} MON\n`);

  if (balance === 0n) {
    throw new Error("Deployer wallet has no MON. Fund it via Monad faucet first.");
  }

  // ── Load artifact ──────────────────────────────────────────────────────────
  if (!fs.existsSync(ARTIFACT_PATH)) {
    throw new Error("Contract artifact not found. Run: npx hardhat compile");
  }

  const artifact = JSON.parse(fs.readFileSync(ARTIFACT_PATH, "utf8"));
  const factory  = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);

  // ── Deploy ────────────────────────────────────────────────────────────────
  console.log("🚀  Deploying PayAgentCompliance.sol...");
  console.log(`🔮  Compliance oracle: ${ORACLE_ADDR}\n`);

  const contract = await factory.deploy(ORACLE_ADDR);
  await contract.waitForDeployment();

  const address  = await contract.getAddress();
  const receipt  = await provider.getTransactionReceipt(contract.deploymentTransaction().hash);

  console.log("✅  DEPLOYED SUCCESSFULLY\n");
  console.log(`📄  Contract address: ${address}`);
  console.log(`🔗  Tx hash:          ${contract.deploymentTransaction().hash}`);
  console.log(`⛽  Gas used:         ${receipt.gasUsed.toString()}`);
  console.log(`🧱  Block:            ${receipt.blockNumber}`);
  console.log(`\n🌐  Explorer: https://explorer.monad.xyz/address/${address}\n`);

  // ── Post-deploy setup ─────────────────────────────────────────────────────
  console.log("⚙️   Running post-deploy setup...");

  // Whitelist USDC on Monad (replace with actual Monad USDC address)
  const MONAD_USDC = process.env.MONAD_USDC_ADDRESS;
  if (MONAD_USDC) {
    const tx = await contract.whitelistToken(MONAD_USDC, true);
    await tx.wait();
    console.log(`✅  USDC whitelisted: ${MONAD_USDC}`);
  }

  // ── Save deployment record ─────────────────────────────────────────────────
  const deployment = {
    network:          "monad-mainnet",
    contractName:     "PayAgentCompliance",
    address,
    txHash:           contract.deploymentTransaction().hash,
    blockNumber:      receipt.blockNumber,
    deployer:         wallet.address,
    oracle:           ORACLE_ADDR,
    deployedAt:       new Date().toISOString(),
    hackathon:        "Cleanverse Build 2026 — Track 02",
    team:             "NormaNova",
  };

  const outPath = path.join(__dirname, "../docs/deployment-record.json");
  fs.writeFileSync(outPath, JSON.stringify(deployment, null, 2));
  console.log(`\n💾  Deployment record saved: docs/deployment-record.json`);
  console.log("═══════════════════════════════════════════════");
}

main().catch((err) => {
  console.error("\n❌  Deployment failed:", err.message);
  process.exit(1);
});
