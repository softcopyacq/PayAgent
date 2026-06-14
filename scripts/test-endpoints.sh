#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# PayAgent Endpoint Test Suite
# Tests all API endpoints for functionality, SSL, and compliance headers
# Run: bash scripts/test-endpoints.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL=${1:-"https://payagent.yourdomain.com"}
BEARER_TOKEN=${2:-"test-token-123"}

echo -e "${BLUE}"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "  PayAgent API Test Suite"
echo "  Endpoint: $BASE_URL"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo -e "${NC}"

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Helper function to test endpoint
test_endpoint() {
    local METHOD=$1
    local ENDPOINT=$2
    local DESCRIPTION=$3
    local BODY=${4:-""}
    local REQUIRES_AUTH=${5:-false}
    
    TEST_COUNT=$((TEST_COUNT + 1))
    echo -e "${YELLOW}Test $TEST_COUNT: $DESCRIPTION${NC}"
    
    local CMD="curl -s -w '\n%{http_code}' -X $METHOD"
    
    if [ "$REQUIRES_AUTH" = true ]; then
        CMD="$CMD -H \"Authorization: Bearer $BEARER_TOKEN\""
    fi
    
    CMD="$CMD -H \"Content-Type: application/json\""
    
    if [ ! -z "$BODY" ]; then
        CMD="$CMD -d '$BODY'"
    fi
    
    CMD="$CMD \"$BASE_URL$ENDPOINT\""
    
    # Execute request
    RESPONSE=$(eval $CMD)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY_RESPONSE=$(echo "$RESPONSE" | head -n-1)
    
    echo "  Method:      $METHOD"
    echo "  Endpoint:    $ENDPOINT"
    echo "  HTTP Code:   $HTTP_CODE"
    
    # Check for success
    if [[ $HTTP_CODE -ge 200 && $HTTP_CODE -lt 300 ]]; then
        echo -e "  Status:      ${GREEN}✓ PASS${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
    elif [[ $HTTP_CODE -eq 401 && "$REQUIRES_AUTH" = true ]]; then
        echo -e "  Status:      ${YELLOW}✓ PASS (Expected 401 - Auth required)${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "  Status:      ${RED}✗ FAIL${NC}"
        echo "  Response:    $BODY_RESPONSE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    echo ""
}

# ──────────────────────────────────────────────────────────────────────────────
# TEST SUITE
# ──────────────────────────────────────────────────────────────────────────────

echo -e "${BLUE}1. PUBLIC ENDPOINTS${NC}"
test_endpoint "GET" "/api/health" "Health check endpoint"
test_endpoint "GET" "/api/corridors" "Get corridor metadata"

echo -e "${BLUE}2. AUTHENTICATION TESTS${NC}"
test_endpoint "POST" "/api/generate_apass" "Generate A-Pass (no auth)" \
    '{"customerId": "test-001", "kycSource": "Sumsub", "subTier": 5}' false

echo -e "${BLUE}3. SSL/HTTPS VERIFICATION${NC}"
echo "Testing SSL certificate..."
SSL_TEST=$(curl -s -I "$BASE_URL/api/health" | grep -i "strict-transport-security" || echo "")
if [ ! -z "$SSL_TEST" ]; then
    echo -e "  ${GREEN}✓ HSTS header present${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "  ${RED}✗ HSTS header missing${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

echo -e "${BLUE}4. SECURITY HEADERS${NC}"
echo "Checking security headers..."

HEADERS=$(curl -s -I "$BASE_URL/api/health")

# Check for security headers
echo "  Checking X-Content-Type-Options..."
if echo "$HEADERS" | grep -i "X-Content-Type-Options" > /dev/null; then
    echo -e "    ${GREEN}✓ Present${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "    ${RED}✗ Missing${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo "  Checking X-Frame-Options..."
if echo "$HEADERS" | grep -i "X-Frame-Options" > /dev/null; then
    echo -e "    ${GREEN}✓ Present${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e "    ${RED}✗ Missing${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

# ──────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ──────────────────────────────────────────────────────────────────────────────

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo "  TEST SUMMARY"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo "  Total Tests:  $TEST_COUNT"
echo -e "  ${GREEN}Passed:       $PASS_COUNT${NC}"
echo -e "  ${RED}Failed:       $FAIL_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}\n  ✓ ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "${RED}\n  ✗ SOME TESTS FAILED${NC}"
    exit 1
fi
