# PayAgent 🔐

> **Verified AI Agent Payments — Lisbon ↔ USA Corridor**
> Built for the [Cleanverse Build: Verified Finance Hackathon](https://cleanverse.com/hackathon) · Supported by Monad Foundation

[![License: MIT](https://img.shields.io/badge/License-MIT-orange.svg)](LICENSE)
[![Track](https://img.shields.io/badge/Track-02%20Trusted%20AI%20Agent%20Transactions-blue)](https://cleanverse.com/hackathon)
[![Network](https://img.shields.io/badge/Network-Monad%20Mainnet-purple)](https://monad.xyz)
[![SSL](https://img.shields.io/badge/SSL-A%2B%20Rated-brightgreen)](https://www.ssllabs.com)
[![Team](https://img.shields.io/badge/Team-NormaNova-orange)](https://github.com/softcopyacq)

---

## What is PayAgent?

PayAgent is a **compliant AI agent payment layer** that wraps every agent-initiated transaction with:

- 🪪 **A-Pass** identity credentials — wallet-bound, bank-verified, KYC'd
- 🪙 **A-Token** compliance wrappers — clean origination, AML/Travel Rule enforced
- 🔒 **AES-encrypted** API calls to Cleanverse v3
- ⛓️ **Monad mainnet** settlement — sub-second finality, EVM compatible
- 📋 **Immutable audit trail** — extractable for FinCEN (US) and MiCA (EU)

**The problem:** AI agents execute payments autonomously but authorization is unverified, non-auditable, and compliance-blind.

**The solution:** PayAgent enforces principal identity, clean funds, and Travel Rule compliance on every single agent-initiated transaction — across the Lisbon ↔ USA corridor and beyond.

---

## Live Demo

```
https://payagent.yourdomain.com
```

### Sample transaction output
```json
{
  "transaction_id": "PAYAGT-LIS-NYC-20260613-0847A2F1",
  "status": "SETTLED",
  "corridor": "Lisbon, PT → New York, USA",
  "amount": "€12,500.00 → $13,412.50 (USDC)",
  "settlement_time": "8.3 seconds",
  "apass_sender": "APAS-EU-PT-KYC-VERIFIED-MiCA",
  "apass_receiver": "APAS-US-NY-KYC-VERIFIED-FinCEN",
  "travel_rule": "COMPLIANT — FATF Rec.16 satisfied",
  "atoken_wrap": "ATOKEN-USDC-CLEAN-ORIGINATION-V3",
  "ccp_check": "PASS — 0 AML flags",
  "monad_tx_hash": "0x3f8a...d92c",
  "audit_ref": "AUDIT-2026-0613-LIS-NYC-PAYAGT"
}
```

---

## Architecture

```
Browser / AI Agent
      │  HTTPS :443
      ▼
 Nginx (reverse proxy)  ←── Let's Encrypt TLS · A+ SSL rated
      │  localhost:3000
      ▼
 PayAgent Server (Node.js)
 ├── Presentation tier  (public/)
 ├── Business Logic tier (src/bll/)
 │     ├── AES encryption middleware
 │     ├── Bearer token auth
 │     ├── Travel Rule validator
 │     └── Corridor compliance rules
 ├── Data Access tier   (src/dal/)
 │     ├── Cleanverse API v3 client
 │     └── Monad RPC client
 └── Smart Contracts    (contracts/)
       └── PayAgentCompliance.sol (Monad mainnet)
```

---

## Hackathon Tracks

| Component | Cleanverse API | Status |
|-----------|---------------|--------|
| A-Pass identity | `POST /generate_apass` | ✅ Integrated |
| A-Token register | `POST /atoken/register_atoken` | ✅ Integrated |
| A-Token launch | `POST /atoken/launch` | ✅ Integrated |
| Wrapped A-Token | `POST /atoken/register_wrapped_atoken` | ✅ Integrated |
| CCP Protocol | Pre-tx rule checks | ✅ Integrated |
| Travel Rule | FATF Rec.16 data | ✅ Integrated |
| Clean Payment Rails | Stablecoin routing | ✅ Integrated |
| Agent Skill Framework | Mandate execution | ✅ Integrated |

---

## Geographic Corridors

| Corridor | Compliance | Settlement |
|----------|-----------|------------|
| 🇵🇹 Lisbon → 🇺🇸 USA | MiCA + FinCEN Travel Rule | ~8s |
| 🇺🇸 USA → 🇵🇹 Lisbon | FinCEN + TFR (EU) | ~9s |
| 🇵🇹 Lisbon → 🇰🇪 Nairobi | MiCA + CBK | ~11s |
| 🇰🇪 Nairobi → 🇺🇸 USA | CBK + FinCEN | ~13s |

*Primary corridor: Lisbon ↔ USA — Monad Blitz Lisbon ecosystem → Cleanverse US infrastructure*

---

## Service Tiers

| Tier | Price | A-Pass | Corridors | Support |
|------|-------|--------|-----------|---------|
| **Free Trial** | $0 / 30 days | 5/month | 1 | Community |
| **Premium** | $299 / month | 500/month | 3 | Email + Telegram |
| **VIP** | $999 / month | Unlimited | All | Dedicated engineer |

---

## Quick Start

### Prerequisites
- Node.js 20+
- Cleanverse sandbox API key (register at cleanverse.com)
- Monad testnet/mainnet wallet

### Installation

```bash
git clone https://github.com/softcopyacq/payagent
cd payagent
npm install
```

### Environment setup

```bash
cp .env.example .env
# Edit .env with your keys — never commit this file
```

```env
CLEANVERSE_API_KEY=your_sandbox_key_here
CLEANVERSE_AES_KEY=your_aes_key_here
MONAD_RPC_URL=https://rpc.monad.xyz
JWT_SECRET=your_jwt_secret_here
NODE_ENV=development
PORT=3000
```

### Run locally

```bash
npm run dev
# → http://localhost:3000
```

### Deploy to production

```bash
# 1. Set up nginx + Let's Encrypt (see docs/deployment.md)
# 2. Configure systemd service
sudo systemctl start payagent

# 3. Verify HTTPS
curl -I https://payagent.yourdomain.com/api/generate_apass
```

---

## Repo Structure

```
payagent/
├── src/
│   ├── dal/                    # Data Access Layer
│   │   ├── cleanverse.js       # Cleanverse API v3 client
│   │   └── monad.js            # Monad RPC client
│   ├── bll/                    # Business Logic Layer
│   │   ├── aes.js              # AES encryption middleware
│   │   ├── auth.js             # Bearer token validation
│   │   ├── compliance.js       # Travel Rule + AML checks
│   │   └── corridors.js        # Geographic corridor rules
│   └── presentation/           # Route handlers
│       ├── apass.js            # A-Pass routes
│       ├── atoken.js           # A-Token routes
│       └── validator.js        # Validator routes
├── contracts/
│   └── PayAgentCompliance.sol  # Monad mainnet contract
├── scripts/
│   ├── deploy.js               # Monad deployment script
│   └── test-endpoints.sh       # HTTPS endpoint tests
├── public/                     # Frontend demo UI
│   ├── index.html
│   ├── app.js
│   └── style.css
├── docs/
│   ├── deployment.md           # Nginx + Let's Encrypt guide
│   ├── api.md                  # API reference
│   └── corridors.md            # Corridor compliance details
├── tests/
│   ├── apass.test.js
│   ├── atoken.test.js
│   └── compliance.test.js
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI
├── .env.example                # Template — no secrets
├── .gitignore
├── package.json
├── server.js                   # Entry point
└── README.md
```

---

## API Reference

All endpoints require HTTPS. AES-encrypted endpoints require `{"data":"<Base64 ciphertext>"}` body.

```
POST /api/generate_apass        — Generate A-Pass credential
POST /api/update_status         — Update A-Pass status
POST /api/atoken/register       — Register A-Token
POST /api/atoken/launch         — Launch A-Token
POST /api/atoken/add_rule       — Add compliance rule
POST /api/validator/register    — Register validator pool
GET  /api/health                — Health check (public)
```

Full docs: [docs/api.md](docs/api.md)

---

## Team

**NormaNova** · Independent developer / hackathon team

| Project | Event | Result |
|---------|-------|--------|
| RegLens | UN Global Hackathon | AI trade compliance RAG pipeline |
| DocGen | IBM Bob Hackathon 2026 · lablab.ai | Ranked #106 |
| PayAgent | Cleanverse Build 2026 | Track 02 submission |

---

## Compliance

PayAgent is built on Cleanverse's compliance infrastructure:
- **MiCA** (EU Markets in Crypto-Assets Regulation)
- **FinCEN** (US Financial Crimes Enforcement Network)
- **FATF Recommendation 16** (Travel Rule)
- **CBK** (Central Bank of Kenya) for East Africa corridor

---

## License

MIT © 2026 NormaNova

---

*Cleanverse Build: Verified Finance Hackathon · Track 02: Trusted AI Agent Transactions · Supported by Monad Foundation · Demo Day: June 18, 2026*
