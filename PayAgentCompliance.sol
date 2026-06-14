// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title  PayAgentCompliance
 * @author NormaNova
 * @notice Verified AI Agent Payment Compliance Contract
 *         Cleanverse Build Hackathon 2026 — Track 02: Trusted AI Agent Transactions
 *         Deployed on Monad Mainnet · Lisbon ↔ USA Corridor
 *
 * @dev    Architecture:
 *         ┌─────────────────────────────────────────────┐
 *         │  AI Agent (off-chain)                       │
 *         │    └─→ PayAgentCompliance.sol (on-chain)    │
 *         │          ├─ verifyMandate()                 │
 *         │          ├─ executePayment()                │
 *         │          ├─ auditLog (immutable)            │
 *         │          └─ travelRuleCheck()               │
 *         └─────────────────────────────────────────────┘
 */

// ─────────────────────────────────────────────────────────────────────────────
// INTERFACES
// ─────────────────────────────────────────────────────────────────────────────

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN CONTRACT
// ─────────────────────────────────────────────────────────────────────────────

contract PayAgentCompliance {

    // ── State variables ───────────────────────────────────────────────────────

    address public owner;
    address public complianceOracle;        // Cleanverse oracle — validates A-Pass off-chain
    bool    public paused;

    uint256 public constant TRAVEL_RULE_THRESHOLD = 1000 * 1e6; // $1,000 USDC (6 decimals)
    uint256 public constant MAX_SINGLE_TX         = 50000 * 1e6; // $50,000 USDC cap

    uint256 private _txCounter;

    // ── Enums ─────────────────────────────────────────────────────────────────

    enum TxStatus   { PENDING, SETTLED, FAILED, REVERSED }
    enum Corridor   { LISBON_USA, USA_LISBON, LISBON_NAIROBI, NAIROBI_USA, OTHER }
    enum TierLevel  { FREE, PREMIUM, VIP }

    // ── Structs ───────────────────────────────────────────────────────────────

    struct APassCredential {
        bytes32 apassId;        // e.g. keccak256("APAS-EU-PT-KYC-2026-0421")
        address wallet;         // wallet this credential is bound to
        bool    kycVerified;
        bool    amlCleared;
        uint8   subTier;        // 1–99
        uint64  issuedAt;
        uint64  expiresAt;
        bool    active;
    }

    struct PaymentMandate {
        bytes32   mandateId;
        address   agent;            // AI agent wallet executing the tx
        address   principal;        // human / institution who authorised
        address   receiver;
        address   token;            // USDC or other A-Token
        uint256   amount;
        Corridor  corridor;
        bool      travelRuleRequired;
        bool      travelRuleSatisfied;
        TxStatus  status;
        uint64    createdAt;
        uint64    settledAt;
        bytes32   auditRef;         // off-chain audit reference
    }

    struct SpendLimit {
        uint256 dailyLimit;
        uint256 dailySpent;
        uint64  lastResetDay;
    }

    // ── Mappings ──────────────────────────────────────────────────────────────

    mapping(bytes32 => APassCredential) public apassRegistry;          // apassId → credential
    mapping(address => bytes32)         public walletToApass;           // wallet → apassId
    mapping(bytes32 => PaymentMandate)  public mandates;                // mandateId → mandate
    mapping(address => bool)            public authorisedAgents;        // approved AI agents
    mapping(address => bool)            public blacklist;               // AML blacklist
    mapping(address => SpendLimit)      public spendLimits;             // per-agent limits
    mapping(address => TierLevel)       public agentTier;              // FREE/PREMIUM/VIP
    mapping(address => bool)            public whitelistedTokens;       // approved A-Tokens

    bytes32[] public allMandateIds;     // iterable list of mandates

    // ── Events (immutable audit trail) ───────────────────────────────────────

    event APassRegistered(
        bytes32 indexed apassId,
        address indexed wallet,
        uint8   subTier,
        uint64  issuedAt
    );

    event APassRevoked(
        bytes32 indexed apassId,
        address indexed wallet,
        uint64  revokedAt
    );

    event MandateCreated(
        bytes32 indexed mandateId,
        address indexed agent,
        address indexed principal,
        uint256 amount,
        Corridor corridor
    );

    event PaymentSettled(
        bytes32 indexed mandateId,
        address indexed receiver,
        uint256 amount,
        address token,
        bytes32 auditRef,
        uint64  settledAt
    );

    event PaymentFailed(
        bytes32 indexed mandateId,
        string  reason
    );

    event TravelRuleCleared(
        bytes32 indexed mandateId,
        address indexed oracle,
        uint64  clearedAt
    );

    event AgentAuthorised(address indexed agent, TierLevel tier);
    event AgentRevoked(address indexed agent);
    event BlacklistUpdated(address indexed wallet, bool blocked);
    event SpendLimitSet(address indexed agent, uint256 dailyLimit);
    event ContractPaused(bool paused);
    event TokenWhitelisted(address indexed token, bool approved);

    // ── Modifiers ─────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "PayAgent: caller is not owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == complianceOracle, "PayAgent: caller is not oracle");
        _;
    }

    modifier onlyAuthorisedAgent() {
        require(authorisedAgents[msg.sender], "PayAgent: agent not authorised");
        _;
    }

    modifier notPaused() {
        require(!paused, "PayAgent: contract is paused");
        _;
    }

    modifier notBlacklisted(address wallet) {
        require(!blacklist[wallet], "PayAgent: wallet is blacklisted");
        _;
    }

    // ── Constructor ───────────────────────────────────────────────────────────

    constructor(address _complianceOracle) {
        owner             = msg.sender;
        complianceOracle  = _complianceOracle;
        paused            = false;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // A-PASS MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Register an A-Pass credential on-chain (called by Cleanverse oracle)
     * @param  apassId     keccak256 hash of the Cleanverse apassId string
     * @param  wallet      wallet address to bind credential to
     * @param  subTier     KYC sub-tier level (1–99)
     * @param  expiresAt   unix timestamp of credential expiry
     */
    function registerAPass(
        bytes32 apassId,
        address wallet,
        uint8   subTier,
        uint64  expiresAt
    ) external onlyOracle notPaused {
        require(wallet != address(0),            "PayAgent: zero address");
        require(subTier >= 1 && subTier <= 99,   "PayAgent: invalid subTier");
        require(expiresAt > block.timestamp,     "PayAgent: already expired");
        require(!apassRegistry[apassId].active,  "PayAgent: apassId already registered");

        apassRegistry[apassId] = APassCredential({
            apassId:     apassId,
            wallet:      wallet,
            kycVerified: true,
            amlCleared:  true,
            subTier:     subTier,
            issuedAt:    uint64(block.timestamp),
            expiresAt:   expiresAt,
            active:      true
        });

        walletToApass[wallet] = apassId;

        emit APassRegistered(apassId, wallet, subTier, uint64(block.timestamp));
    }

    /**
     * @notice Revoke an A-Pass credential (compliance action)
     */
    function revokeAPass(bytes32 apassId) external onlyOracle {
        APassCredential storage cred = apassRegistry[apassId];
        require(cred.active, "PayAgent: credential not active");
        cred.active = false;
        emit APassRevoked(apassId, cred.wallet, uint64(block.timestamp));
    }

    /**
     * @notice Check whether a wallet holds a valid, unexpired A-Pass
     */
    function isAPassValid(address wallet) public view returns (bool) {
        bytes32 apassId = walletToApass[wallet];
        if (apassId == bytes32(0)) return false;
        APassCredential memory cred = apassRegistry[apassId];
        return (
            cred.active &&
            cred.kycVerified &&
            cred.amlCleared &&
            cred.expiresAt > block.timestamp
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MANDATE MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice AI agent creates a payment mandate before execution
     * @param  principal  wallet of the human/institution authorising payment
     * @param  receiver   destination wallet
     * @param  token      whitelisted A-Token (USDC etc.)
     * @param  amount     token amount (in token's decimals)
     * @param  corridor   geographic corridor enum
     * @param  auditRef   off-chain Cleanverse audit reference
     */
    function createMandate(
        address  principal,
        address  receiver,
        address  token,
        uint256  amount,
        Corridor corridor,
        bytes32  auditRef
    )
        external
        onlyAuthorisedAgent
        notPaused
        notBlacklisted(msg.sender)
        notBlacklisted(principal)
        notBlacklisted(receiver)
        returns (bytes32 mandateId)
    {
        // ── Validations ───────────────────────────────────────────────────────
        require(whitelistedTokens[token],      "PayAgent: token not whitelisted");
        require(amount > 0,                    "PayAgent: amount must be > 0");
        require(amount <= MAX_SINGLE_TX,       "PayAgent: exceeds single tx cap");
        require(isAPassValid(principal),       "PayAgent: principal A-Pass invalid");
        require(isAPassValid(receiver),        "PayAgent: receiver A-Pass invalid");

        // ── Spend limit check ─────────────────────────────────────────────────
        _checkAndUpdateSpendLimit(msg.sender, amount);

        // ── Travel Rule flag ──────────────────────────────────────────────────
        bool travelRuleRequired = amount >= TRAVEL_RULE_THRESHOLD;

        // ── Create mandate ────────────────────────────────────────────────────
        _txCounter++;
        mandateId = keccak256(
            abi.encodePacked(msg.sender, principal, receiver, amount, block.timestamp, _txCounter)
        );

        mandates[mandateId] = PaymentMandate({
            mandateId:            mandateId,
            agent:                msg.sender,
            principal:            principal,
            receiver:             receiver,
            token:                token,
            amount:               amount,
            corridor:             corridor,
            travelRuleRequired:   travelRuleRequired,
            travelRuleSatisfied:  !travelRuleRequired, // auto-satisfied if below threshold
            status:               TxStatus.PENDING,
            createdAt:            uint64(block.timestamp),
            settledAt:            0,
            auditRef:             auditRef
        });

        allMandateIds.push(mandateId);

        emit MandateCreated(mandateId, msg.sender, principal, amount, corridor);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TRAVEL RULE CLEARANCE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Cleanverse oracle clears Travel Rule for mandates ≥ $1,000
     *         Called after FATF Rec.16 data verified off-chain
     */
    function clearTravelRule(bytes32 mandateId) external onlyOracle {
        PaymentMandate storage m = mandates[mandateId];
        require(m.status == TxStatus.PENDING,      "PayAgent: mandate not pending");
        require(m.travelRuleRequired,              "PayAgent: Travel Rule not required");
        require(!m.travelRuleSatisfied,            "PayAgent: already cleared");

        m.travelRuleSatisfied = true;

        emit TravelRuleCleared(mandateId, msg.sender, uint64(block.timestamp));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PAYMENT EXECUTION
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Execute a verified payment mandate
     *         All compliance checks must pass before tokens move
     * @param  mandateId   mandate to execute
     */
    function executePayment(bytes32 mandateId)
        external
        onlyAuthorisedAgent
        notPaused
        returns (bool)
    {
        PaymentMandate storage m = mandates[mandateId];

        require(m.agent == msg.sender,             "PayAgent: not mandate agent");
        require(m.status == TxStatus.PENDING,      "PayAgent: mandate not pending");
        require(m.travelRuleSatisfied,             "PayAgent: Travel Rule not cleared");
        require(isAPassValid(m.principal),         "PayAgent: principal A-Pass invalid");
        require(isAPassValid(m.receiver),          "PayAgent: receiver A-Pass invalid");
        require(!blacklist[m.receiver],            "PayAgent: receiver blacklisted");

        IERC20 token = IERC20(m.token);

        // Check allowance
        uint256 allowance = token.allowance(m.principal, address(this));
        if (allowance < m.amount) {
            m.status = TxStatus.FAILED;
            emit PaymentFailed(mandateId, "Insufficient allowance");
            return false;
        }

        // Execute transfer
        bool success = token.transferFrom(m.principal, m.receiver, m.amount);

        if (success) {
            m.status    = TxStatus.SETTLED;
            m.settledAt = uint64(block.timestamp);

            emit PaymentSettled(
                mandateId,
                m.receiver,
                m.amount,
                m.token,
                m.auditRef,
                uint64(block.timestamp)
            );
        } else {
            m.status = TxStatus.FAILED;
            emit PaymentFailed(mandateId, "Token transfer failed");
        }

        return success;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SPEND LIMIT (Agent Skill Framework)
    // ─────────────────────────────────────────────────────────────────────────

    function _checkAndUpdateSpendLimit(address agent, uint256 amount) internal {
        SpendLimit storage sl = spendLimits[agent];

        // Reset daily counter if new day
        uint64 today = uint64(block.timestamp / 1 days);
        if (sl.lastResetDay < today) {
            sl.dailySpent    = 0;
            sl.lastResetDay  = today;
        }

        // VIP tier — no limit
        if (agentTier[agent] == TierLevel.VIP) return;

        // Premium: $10,000/day default
        uint256 effectiveLimit = sl.dailyLimit > 0
            ? sl.dailyLimit
            : (agentTier[agent] == TierLevel.PREMIUM ? 10000 * 1e6 : 1000 * 1e6);

        require(
            sl.dailySpent + amount <= effectiveLimit,
            "PayAgent: daily spend limit exceeded"
        );

        sl.dailySpent += amount;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ADMIN — AGENT MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    function authoriseAgent(address agent, TierLevel tier) external onlyOwner {
        require(agent != address(0), "PayAgent: zero address");
        authorisedAgents[agent] = true;
        agentTier[agent]        = tier;
        emit AgentAuthorised(agent, tier);
    }

    function revokeAgent(address agent) external onlyOwner {
        authorisedAgents[agent] = false;
        emit AgentRevoked(agent);
    }

    function setSpendLimit(address agent, uint256 dailyLimit) external onlyOwner {
        spendLimits[agent].dailyLimit = dailyLimit;
        emit SpendLimitSet(agent, dailyLimit);
    }

    function updateBlacklist(address wallet, bool blocked) external onlyOracle {
        blacklist[wallet] = blocked;
        emit BlacklistUpdated(wallet, blocked);
    }

    function whitelistToken(address token, bool approved) external onlyOwner {
        require(token != address(0), "PayAgent: zero address");
        whitelistedTokens[token] = approved;
        emit TokenWhitelisted(token, approved);
    }

    function setComplianceOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "PayAgent: zero address");
        complianceOracle = oracle;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit ContractPaused(_paused);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "PayAgent: zero address");
        owner = newOwner;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VIEWS — AUDIT & REPORTING
    // ─────────────────────────────────────────────────────────────────────────

    function getMandate(bytes32 mandateId)
        external view
        returns (PaymentMandate memory)
    {
        return mandates[mandateId];
    }

    function getAPass(bytes32 apassId)
        external view
        returns (APassCredential memory)
    {
        return apassRegistry[apassId];
    }

    function getMandateCount() external view returns (uint256) {
        return allMandateIds.length;
    }

    function getAgentSpendToday(address agent)
        external view
        returns (uint256 spent, uint256 limit)
    {
        SpendLimit memory sl = spendLimits[agent];
        uint64 today = uint64(block.timestamp / 1 days);
        spent = sl.lastResetDay < today ? 0 : sl.dailySpent;
        limit = sl.dailyLimit > 0
            ? sl.dailyLimit
            : (agentTier[agent] == TierLevel.PREMIUM ? 10000 * 1e6 : 1000 * 1e6);
    }

    /**
     * @notice Returns all mandate IDs for off-chain audit export
     *         Extractable for FinCEN (US) and MiCA (EU) regulators
     */
    function getAllMandateIds() external view returns (bytes32[] memory) {
        return allMandateIds;
    }
}
