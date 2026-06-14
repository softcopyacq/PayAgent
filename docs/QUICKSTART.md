# Quick Start Guide

## 5-Minute Local Setup

### Prerequisites
- Node.js 20+
- npm 10+
- Git

### Step 1: Clone Repository

```bash
git clone https://github.com/softcopyacq/PayAgent.git
cd PayAgent
```

### Step 2: Install Dependencies

```bash
npm install
```

### Step 3: Create Environment File

```bash
cp .env.example .env
```

Edit `.env` with your credentials:

```bash
PORT=3000
NODE_ENV=development

# Get these from https://cleanverse.com
CLEANVERSE_API_KEY=your_sandbox_api_key
CLEANVERSE_AES_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

# Monad
MONAD_RPC_URL=https://rpc.monad.xyz

# Security
JWT_SECRET=your_secret_min_32_characters_here
```

### Step 4: Start Server

```bash
npm run dev
```

**Expected Output:**

```
╔══════════════════════════════════════════════════════╗
║           PayAgent Server — NormaNova               ║
║    Cleanverse Build Hackathon 2026 · Track 02       ║
║  Status   : RUNNING                                 ║
║  Port     : 3000                                    ║
│  Mode     : development                             ║
╚══════════════════════════════════════════════════════╝
```

### Step 5: Test Health Endpoint

```bash
curl http://localhost:3000/api/health
```

**Response:**

```json
{
  "status": "ok",
  "service": "PayAgent",
  "version": "1.0.0",
  "network": "https://rpc.monad.xyz",
  "corridors": [
    "LISBON_USA",
    "USA_LISBON",
    "LISBON_NAIROBI",
    "NAIROBI_USA"
  ]
}
```

✅ **Success!** PayAgent is running locally.

---

## Next Steps

1. **Test API endpoints** — Run: `bash scripts/test-endpoints.sh http://localhost:3000`
2. **Run unit tests** — Run: `npm test`
3. **Deploy to production** — Follow: `docs/deployment.md`
4. **Deploy smart contract** — Run: `npm run deploy:monad-mainnet`

---

## Troubleshooting

### Port 3000 already in use

```bash
PORT=3001 npm run dev
```

### Missing environment variables

Check `.env` exists and contains:
- `CLEANVERSE_API_KEY`
- `CLEANVERSE_AES_KEY`
- `JWT_SECRET`
- `MONAD_RPC_URL`

### Connection refused

Make sure Monad RPC is accessible:

```bash
curl -I https://rpc.monad.xyz
```

---

*For full documentation, see `docs/deployment.md` and `docs/api.md`*
