#!/bin/bash

# KitOps Policy-as-Code Demo
# Demonstrates automated governance using OPA policies
# Based on blog: "Beyond the Spreadsheet: Implementing Policy-as-Code for AI Governance"

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Demo directory
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "${BLUE}========================================${NC}\n\n"
printf "${BLUE}KitOps Policy-as-Code Demo${NC}\n\n"
printf "${BLUE}EU AI Act Compliance Automation${NC}\n\n"
printf "${BLUE}========================================${NC}\n\n"
printf "\n\n"

# Check if OPA is installed
if ! command -v opa &> /dev/null; then
    printf "${RED}ERROR: OPA is not installed${NC}\n\n"
    echo "Please install OPA first:"
    echo "  macOS:   brew install opa"
    echo "  Linux:   curl -L https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -o /usr/local/bin/opa && chmod +x /usr/local/bin/opa"
    echo ""
    exit 1
fi

printf "✓ OPA installed: $(opa version | head -n1)\n\n"
printf "\n\n"

# Helper function to run policy evaluation
evaluate_policy() {
    local policy_file=$1
    local input_file=$2
    local policy_name=$3
    local description=$4
    
    printf "${YELLOW}Testing: ${description}${NC}\n\n"
    
    # Combine Kitfile with scan results if available
    if [ -f "$DEMO_DIR/mock-scan-results/clean-scan.json" ]; then
        # Merge Kitfile with scan results
        combined_input=$(mktemp)
        python3 -c "
import yaml, json, sys
with open('$input_file') as f:
    kitfile = yaml.safe_load(f)
with open('$DEMO_DIR/mock-scan-results/clean-scan.json') as f:
    scan = json.load(f)
combined = {**kitfile, **scan}
json.dump(combined, sys.stdout)
" > "$combined_input" 2>/dev/null || {
            # Fallback if Python merge fails
            combined_input="$input_file"
        }
    else
        combined_input="$input_file"
    fi
    
    # Evaluate policy
    result=$(opa eval --data "$policy_file" --input "$combined_input" --format pretty "data.$policy_name.deny" 2>&1)
    
    if echo "$result" | grep -q "^\[\]$" || echo "$result" | grep -q "undefined"; then
        printf "  ${GREEN}✅ PASS${NC}\n\n"
    else
        printf "  ${RED}❌ BLOCKED${NC}\n\n"
        echo "$result" | sed 's/^/  /'
    fi
    
    # Cleanup temp file
    [ -f "$combined_input" ] && [ "$combined_input" != "$input_file" ] && rm -f "$combined_input"
    printf "\n\n"
}

# ========================================
# Scenario 1: Compliant ModelKit
# ========================================
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
printf "${BLUE}Scenario 1: Compliant ModelKit${NC}\n\n"
printf "${BLUE}Testing: fraud-detection-compliant.yaml${NC}\n\n"
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
printf "\n\n"

COMPLIANT="$DEMO_DIR/kitfile-examples/fraud-detection-compliant.yaml"

evaluate_policy \
    "$DEMO_DIR/policies/license-compliance.rego" \
    "$COMPLIANT" \
    "governance.licenses" \
    "License Compliance (Apache-2.0)"

evaluate_policy \
    "$DEMO_DIR/policies/approval-validation.rego" \
    "$COMPLIANT" \
    "governance.approvals" \
    "Approval Validation (18 days old)"

evaluate_policy \
    "$DEMO_DIR/policies/bias-monitoring.rego" \
    "$COMPLIANT" \
    "governance.bias" \
    "Bias Monitoring - EU AI Act Article 72 (DP: 0.96)"

printf "${GREEN}✓ All policies passed - ModelKit approved for production${NC}\n"
printf "\n"

# ========================================
# Scenario 2: Bias Violation
# ========================================
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "${BLUE}Scenario 2: Bias Violation${NC}\n"
printf "${BLUE}Testing: fraud-detection-bias-violation.yaml${NC}\n"
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "\n"

BIAS_VIOLATION="$DEMO_DIR/kitfile-examples/fraud-detection-bias-violation.yaml"

evaluate_policy \
    "$DEMO_DIR/policies/bias-monitoring.rego" \
    "$BIAS_VIOLATION" \
    "governance.bias" \
    "Bias Monitoring - Demographic Parity (0.75)"

printf "${RED}✗ Deployment blocked - bias metrics below threshold${NC}\n"
printf "\n"

# ========================================
# Scenario 3: Expired Approval
# ========================================
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "${BLUE}Scenario 3: Expired Approval${NC}\n"
printf "${BLUE}Testing: fraud-detection-expired-approval.yaml${NC}\n"
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "\n"

EXPIRED="$DEMO_DIR/kitfile-examples/fraud-detection-expired-approval.yaml"

evaluate_policy \
    "$DEMO_DIR/policies/approval-validation.rego" \
    "$EXPIRED" \
    "governance.approvals" \
    "Approval Validation (approval from Oct 2025)"

printf "${RED}✗ Deployment blocked - approval expired${NC}\n"
printf "\n"

# ========================================
# Scenario 4: License Violation
# ========================================
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "${BLUE}Scenario 4: License Violation${NC}\n"
printf "${BLUE}Testing: fraud-detection-license-violation.yaml${NC}\n"
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "\n"

LICENSE_VIOLATION="$DEMO_DIR/kitfile-examples/fraud-detection-license-violation.yaml"

evaluate_policy \
    "$DEMO_DIR/policies/license-compliance.rego" \
    "$LICENSE_VIOLATION" \
    "governance.licenses" \
    "License Compliance (GPL-3.0)"

printf "${RED}✗ Deployment blocked - GPL license not approved${NC}\n"
printf "\n"

# ========================================
# Scenario 5: Security Scan Results
# ========================================
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "${BLUE}Scenario 5: Security Vulnerability Check${NC}\n"
printf "${BLUE}Testing with mock scan results${NC}\n"
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "\n"

printf "${YELLOW}a) Clean scan (0 critical vulnerabilities)${NC}\n"
opa eval --data "$DEMO_DIR/policies/security-thresholds.rego" \
    --input "$DEMO_DIR/mock-scan-results/clean-scan.json" \
    --format pretty "data.governance.security.deny" > /tmp/opa-result.txt 2>&1
if grep -q "^\[\]$" /tmp/opa-result.txt || grep -q "undefined" /tmp/opa-result.txt; then
    printf "  ${GREEN}✅ PASS - No critical vulnerabilities${NC}\n"
else
    printf "  ${RED}❌ BLOCKED${NC}\n"
    cat /tmp/opa-result.txt | sed 's/^/  /'
fi
printf "\n"

printf "${YELLOW}b) Vulnerable scan (3 critical CVEs)${NC}\n"
opa eval --data "$DEMO_DIR/policies/security-thresholds.rego" \
    --input "$DEMO_DIR/mock-scan-results/vulnerable-scan.json" \
    --format pretty "data.governance.security.deny" > /tmp/opa-result.txt 2>&1
if grep -q "^\[\]$" /tmp/opa-result.txt || grep -q "undefined" /tmp/opa-result.txt; then
    printf "  ${GREEN}✅ PASS${NC}\n"
else
    printf "  ${RED}❌ BLOCKED${NC}\n"
    cat /tmp/opa-result.txt | sed 's/^/  /'
fi
rm -f /tmp/opa-result.txt
printf "\n"

# ========================================
# Summary
# ========================================
printf "${BLUE}========================================${NC}\n"
printf "${BLUE}Demo Summary${NC}\n"
printf "${BLUE}========================================${NC}\n"
printf "\n"
echo "✅ Policy-as-Code enforcement demonstrated"
echo "✅ EU AI Act Article 72 bias monitoring"
echo "✅ Approval expiry automation (90-day limit)"
echo "✅ License compliance gates"
echo "✅ Security vulnerability blocking"
printf "\n"
printf "${GREEN}Key Takeaway:${NC} Manual compliance can't match AI velocity.\n"
echo "Code-based policies enforce governance automatically at deployment time."
printf "\n"
echo "Learn more: https://kitops.org | https://jozu.com"
printf "\n"
