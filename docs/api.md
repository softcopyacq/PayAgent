# API Reference

## PayAgent REST API Documentation

### Base URL

```
https://payagent.yourdomain.com/api
```

### Authentication

All endpoints (except `/health` and `/corridors`) require:

```bash
Authorization: Bearer <YOUR_TOKEN>
Content-Type: application/json
```

### Encryption

Some endpoints require **AES-256-CBC encrypted payloads**:

```json
{
  "data": "<Base64-encoded ciphertext>"
}
```

The server handles encryption/decryption automatically.

---

## Endpoints

### 1. Health Check (Public)

**GET** `/api/health`

No authentication required.

#### Response

```json
{
  "status": "ok",
  "service": "PayAgent",
  "version": "1.0.0",
  "network": "https://rpc.monad.xyz",
  "timestamp": "2026-06-14T20:00:00.000Z",
  "corridors": [
    "LISBON_USA",
    "USA_LISBON",
    "LISBON_NAIROBI",
    "NAIROBI_USA"
  ]
}
```

---

### 2. Corridor Metadata (Public)

**GET** `/api/corridors`

No authentication required.

#### Response

```json
{
  "corridors": {
    "LISBON_USA": {
      "frameworks": ["MiCA", "FinCEN", "FATF-Rec16"],
      "settlementMs": 8300
    },
    "USA_LISBON": {
      "frameworks": ["FinCEN", "TFR-EU", "FATF-Rec16"],
      "settlementMs": 9100
    },
    "LISBON_NAIROBI": {
      "frameworks": ["MiCA", "CBK", "FATF-Rec16"],
      "settlementMs": 11200
    },
    "NAIROBI_USA": {
      "frameworks": ["CBK", "FinCEN", "FATF-Rec16"],
      "settlementMs": 13000
    }
  }
}
```

---

### 3. Generate A-Pass (AES Encrypted)

**POST** `/api/generate_apass`

Authentication: **Required** (Bearer token)

Rate limit: **Free tier** (100 req/day)

#### Request

```json
{
  "customerId": "agent-001-lisbon",
  "kycSource": "Sumsub",
  "kycId": "KYC-12345-EU",
  "subTier": 5
}
```

#### Response

```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "apassId": "APAS-EU-PT-KYC-VERIFIED-MiCA",
  "customerId": "agent-001-lisbon",
  "status": "ACTIVE",
  "kycVerified": true,
  "subTier": 5,
  "corridor": "EU-MiCA → US-FinCEN",
  "walletBound": true,
  "issuedAt": "2026-06-14T20:00:00.000Z",
  "auditRef": "AUDIT-APASS-550E8400"
}
```

---

### 4. Update A-Pass Status

**POST** `/api/update_status`

Authentication: **Required**

#### Request

```json
{
  "apassId": "APAS-EU-PT-KYC-VERIFIED-MiCA",
  "status": "SUSPENDED",
  "reason": "Compliance review pending"
}
```

#### Status Values

- `ACTIVE` — credential is valid
- `SUSPENDED` — temporarily blocked pending review
- `REVOKED` — permanently invalidated

#### Response

```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440001",
  "apassId": "APAS-EU-PT-KYC-VERIFIED-MiCA",
  "status": "SUSPENDED",
  "updatedAt": "2026-06-14T20:05:00.000Z"
}
```

---

### 5. Register A-Token (AES Encrypted)

**POST** `/api/atoken/register`

Authentication: **Required**

Rate limit: **Premium tier** (200 req/min)

#### Request

```json
{
  "tokenName": "Compliant USDC",
  "tokenSymbol": "USDC-CLEAN",
  "totalSupply": 1000000,
  "decimals": 6,
  "apassId": "APAS-EU-PT-KYC-VERIFIED-MiCA"
}
```

#### Response

```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440002",
  "tokenId": "ATOKEN-USDC-CLEAN-V3",
  "tokenName": "Compliant USDC",
  "tokenSymbol": "USDC-CLEAN",
  "status": "REGISTERED",
  "monadNetwork": "https://rpc.monad.xyz",
  "auditRef": "AUDIT-ATOKEN-550E8400"
}
```

---

### 6. Launch A-Token

**POST** `/api/atoken/launch`

Authentication: **Required**

#### Request

```json
{
  "tokenId": "ATOKEN-USDC-CLEAN-V3",
  "launchDate": "2026-06-15T00:00:00Z",
  "initialPrice": 1.0
}
```

#### Response

```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440003",
  "tokenId": "ATOKEN-USDC-CLEAN-V3",
  "status": "LAUNCHED",
  "launchedAt": "2026-06-14T20:10:00.000Z",
  "tradingEnabled": true
}
```

---

### 7. Add Compliance Rule to A-Token

**POST** `/api/atoken/add_rule`

Authentication: **Required**

#### Request

```json
{
  "tokenId": "ATOKEN-USDC-CLEAN-V3",
  "ruleType": "TRAVEL_RULE",
  "ruleValue": "1000"
}
```

#### Rule Types

- `AML` — Anti-Money Laundering checks
- `KYC` — Know Your Customer verification
- `TRAVEL_RULE` — FATF Rec.16 data exchange
- `SPEND_LIMIT` — Daily/monthly spend caps
- `BLACKLIST` — Address blacklist enforcement

#### Response

```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440004",
  "ruleId": "RULE-1623697800000",
  "tokenId": "ATOKEN-USDC-CLEAN-V3",
  "ruleType": "TRAVEL_RULE",
  "ruleValue": "1000",
  "status": "ACTIVE"
}
```

---

### 8. Pause/Unpause A-Token

**POST** `/api/atoken/set_paused`

Authentication: **Required**

#### Request

```json
{
  "tokenId": "ATOKEN-USDC-CLEAN-V3",
  "paused": true,
  "reason": "Maintenance window"
}
```

#### Response

```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440005",
  "tokenId": "ATOKEN-USDC-CLEAN-V3",
  "paused": true,
  "updatedAt": "2026-06-14T20:15:00.000Z"
}
```

---

### 9. Register Validator Pool

**POST** `/api/validator/register`

Authentication: **Required**

Note: This endpoint uses **plain JSON** (no AES encryption).

#### Request

```json
{
  "poolName": "Monad Lisbon Validators",
  "validatorAddress": "0x1234567890123456789012345678901234567890",
  "jurisdiction": "EU-USA"
}
```

#### Response

```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440006",
  "poolId": "VPOOL-EU-USA-1623697800000",
  "poolName": "Monad Lisbon Validators",
  "jurisdiction": "EU-USA",
  "status": "ACTIVE"
}
```

---

### 10. Set Validator Rule

**POST** `/api/validator/set_rule`

Authentication: **Required**

#### Request

```json
{
  "poolId": "VPOOL-EU-USA-1623697800000",
  "ruleType": "MIN_STAKE",
  "threshold": 32
}
```

#### Response

```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440007",
  "poolId": "VPOOL-EU-USA-1623697800000",
  "ruleType": "MIN_STAKE",
  "threshold": 32,
  "status": "ACTIVE",
  "enforcedFrom": "2026-06-14T20:20:00.000Z"
}
```

---

### 11. Execute Payment (Core PayAgent Flow)

**POST** `/api/pay`

Authentication: **Required**

Rate limit: **Premium tier**

#### Request

```json
{
  "senderApassId": "APAS-EU-PT-KYC-VERIFIED-MiCA",
  "receiverApassId": "APAS-US-NY-KYC-VERIFIED-FinCEN",
  "amount": "12500",
  "currency": "USDC",
  "corridor": "LISBON_USA",
  "mandate": {}
}
```

#### Response

```json
{
  "success": true,
  "transaction_id": "PAYAGT-LIS-1623697800000",
  "status": "SETTLED",
  "corridor": "LISBON_USA",
  "amount": "12500 USDC",
  "settlement_time": "8.3 seconds",
  "apass_sender": "APAS-EU-PT-KYC-VERIFIED-MiCA",
  "apass_receiver": "APAS-US-NY-KYC-VERIFIED-FinCEN",
  "travel_rule": "COMPLIANT — FATF Rec.16 satisfied",
  "atoken_wrap": "ATOKEN-USDC-CLEAN-ORIGINATION-V3",
  "ccp_check": "PASS — 0 AML flags",
  "compliance": ["MiCA", "FinCEN", "FATF-Rec16"],
  "monad_tx_hash": "0x3f8a7b9c2d4e1f6a8c9d0e1f2a3b4c5d6e7f8a9b",
  "monad_network": "https://rpc.monad.xyz",
  "audit_ref": "AUDIT-550E8400",
  "settled_at": "2026-06-14T20:25:00.000Z"
}
```

---

## Error Responses

### 400 Bad Request

```json
{
  "error": "Missing or invalid parameter",
  "detail": "customerId must be at least 12 characters"
}
```

### 401 Unauthorized

```json
{
  "error": "Missing or invalid Authorization header"
}
```

### 403 Forbidden (Compliance)

```json
{
  "error": "CCP pre-check failed",
  "reason": "Sender wallet blacklisted",
  "auditRef": "AUDIT-550E8400"
}
```

### 429 Too Many Requests

```json
{
  "error": "Free tier: rate limit exceeded (100 req/day). Upgrade to Premium."
}
```

### 502 Bad Gateway (Cleanverse API)

```json
{
  "error": "Cleanverse API error",
  "detail": "Connection timeout"
}
```

### 500 Internal Server Error

```json
{
  "error": "Internal server error"
}
```

---

## Rate Limits

| Tier | Requests/Day | Requests/Min | Endpoints |
|------|--------------|--------------|----------|
| **Free** | 100 | — | /generate_apass, /update_status |
| **Premium** | Unlimited | 200 | /atoken/*, /pay, /validator/* |
| **VIP** | Unlimited | Unlimited | All |

---

## Examples

### Example 1: Generate A-Pass

```bash
curl -X POST https://payagent.yourdomain.com/api/generate_apass \
  -H "Authorization: Bearer your-token-here" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "agent-001-lisbon",
    "kycSource": "Sumsub",
    "subTier": 5
  }'
```

### Example 2: Execute Payment

```bash
curl -X POST https://payagent.yourdomain.com/api/pay \
  -H "Authorization: Bearer your-token-here" \
  -H "Content-Type: application/json" \
  -d '{
    "senderApassId": "APAS-EU-PT-KYC-VERIFIED-MiCA",
    "receiverApassId": "APAS-US-NY-KYC-VERIFIED-FinCEN",
    "amount": "12500",
    "currency": "USDC",
    "corridor": "LISBON_USA"
  }'
```

---

## Support

For issues or questions:
- Check `docs/deployment.md` for setup help
- Review `server.js` for implementation details
- Test with `bash scripts/test-endpoints.sh`

---

*PayAgent v1.0 · Cleanverse Build 2026 · Track 02: Trusted AI Agent Transactions*
