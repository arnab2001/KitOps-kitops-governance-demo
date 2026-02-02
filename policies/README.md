# OPA Policies

This directory contains production-ready Rego policies for AI governance.

## Policy Files

### 1. `license-compliance.rego`
**Purpose:** Enforce approved software licenses

**Rules:**
- Only allows: Apache-2.0, MIT, BSD-3-Clause, Proprietary-Internal
- Blocks: GPL, LGPL, AGPL, and other copyleft licenses
- Requires license field to be present

**Example violation:**
```yaml
package:
  license: GPL-3.0  # ❌ BLOCKED
```

**Policy package:** `governance.licenses`

---

### 2. `approval-validation.rego`
**Purpose:** Enforce human oversight for high-risk models (EU AI Act Article 14)

**Rules:**
- High-risk models require `approved_by` field
- High-risk models require `approval_date` field
- Approvals expire after 90 days for high-risk models
- Medium/low-risk models exempt from approval requirements

**Example violation:**
```yaml
parameters:
  risk_level: high
  approval_date: "2025-10-01T09:00:00Z"  # ❌ 124 days old
```

**Policy package:** `governance.approvals`

---

### 3. `bias-monitoring.rego`
**Purpose:** Enforce EU AI Act Article 72 fairness requirements

**Rules:**
- High-risk models require `bias_metrics` object
- Demographic parity must be ≥ 0.80 (80% rule from disparate impact)
- Equalized odds must be ≥ 0.85
- Both `demographic_parity` and `equalized_odds` must be present

**Example violation:**
```yaml
parameters:
  risk_level: high
  bias_metrics:
    demographic_parity: 0.75  # ❌ Below 0.80 threshold
    equalized_odds: 0.94
```

**Policy package:** `governance.bias`

**Regulatory reference:**
- EU AI Act Article 72: Post-market monitoring of bias
- EEOC 80% rule (Uniform Guidelines on Employee Selection)

---

### 4. `security-thresholds.rego`
**Purpose:** Block vulnerable models from production

**Rules:**
- Zero critical vulnerabilities allowed
- Maximum 5 high-severity vulnerabilities
- Zero malware detections
- Zero exposed secrets (API keys, tokens, credentials)

**Input format:**
Expects `scan_results` object from Jozu Hub:
```json
{
  "scan_results": {
    "vulnerability": {
      "critical_count": 0,
      "high_count": 2
    },
    "malware": {
      "threats_detected": 0
    },
    "secrets": {
      "count": 0
    }
  }
}
```

**Policy package:** `governance.security`

---

## Testing Policies Locally

### Install OPA
```bash
# macOS
brew install opa

# Linux
curl -L https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -o /usr/local/bin/opa
chmod +x /usr/local/bin/opa
```

### Test Single Policy
```bash
# Test license policy
opa eval --data license-compliance.rego \
         --input ../kitfile-examples/fraud-detection-compliant.yaml \
         --format pretty \
         "data.governance.licenses.deny"

# Empty array [] or "undefined" means PASS
# Any string output means BLOCKED with reason
```

### Test All Policies Against One Kitfile
```bash
for policy in *.rego; do
    echo "=== Testing $policy ==="
    opa eval --data "$policy" \
             --input ../kitfile-examples/fraud-detection-compliant.yaml \
             --format pretty
done
```

### Run Policy Unit Tests
Create a test file `test-policies.sh`:
```bash
#!/bin/bash
test_policy() {
    local policy=$1
    local input=$2
    local expected=$3  # "pass" or "deny"
    
    result=$(opa eval --data "$policy" --input "$input" --format raw "data.governance.*.deny")
    
    if [[ "$expected" == "pass" && "$result" == "[]" ]]; then
        echo "✅ PASS: $policy with $input"
    elif [[ "$expected" == "deny" && "$result" != "[]" ]]; then
        echo "✅ PASS: $policy correctly denied $input"
    else
        echo "❌ FAIL: $policy with $input"
    fi
}

# Test license policy
test_policy "license-compliance.rego" "../kitfile-examples/fraud-detection-compliant.yaml" "pass"
test_policy "license-compliance.rego" "../kitfile-examples/fraud-detection-license-violation.yaml" "deny"

# Test bias policy
test_policy "bias-monitoring.rego" "../kitfile-examples/fraud-detection-compliant.yaml" "pass"
test_policy "bias-monitoring.rego" "../kitfile-examples/fraud-detection-bias-violation.yaml" "deny"

# Add more tests...
```

## Policy Development Workflow

### 1. Write Policy in Rego
```rego
package governance.mycheck

deny[msg] {
    # Your logic here
    msg := "Violation reason"
}
```

### 2. Test with Sample Data
```bash
echo '{"test": "data"}' | opa eval --data mypolicy.rego --input - "data.governance.mycheck.deny"
```

### 3. Add to Jozu Hub
Once tested, add policy to Jozu Hub's OPA configuration:
```yaml
# In jozu-hub-config.yaml
policies:
  - name: mycheck
    path: /policies/mypolicy.rego
    enabled: true
```

## Customizing Policies

### Change Bias Thresholds
```rego
# In bias-monitoring.rego, line ~10
dp < 0.80  # Change to 0.85 for stricter enforcement
```

### Add New Allowed License
```rego
# In license-compliance.rego, lines ~9-13
allowed_licenses := {
    "Apache-2.0",
    "MIT",
    "BSD-3-Clause",
    "Proprietary-Internal",
    "ISC"  # Add new license here
}
```

### Change Approval Expiry Window
```rego
# In approval-validation.rego, line ~26
age_days > 90  # Change to 60 or 120 days
```

### Adjust Security Thresholds
```rego
# In security-thresholds.rego, line ~15
high > 5  # Change threshold for high-severity vulnerabilities
```

## Advanced: Combining Policies

You can query multiple policies in one evaluation:

```bash
# Load all policies and check all violations
opa eval --data . \
         --input ../kitfile-examples/fraud-detection-bias-violation.yaml \
         --format pretty \
         "data.governance"
```

Output shows results from all policy packages.

## OPA Language Reference

### Common Patterns

**Check if field exists:**
```rego
not input.package.license  # Field is missing
```

**Check if value in set:**
```rego
import future.keywords.in
license := input.package.license
not license in allowed_licenses
```

**String formatting:**
```rego
msg := sprintf("Value %s invalid (expected %v)", [actual, expected])
```

**Time calculations:**
```rego
approval := time.parse_rfc3339_ns(input.parameters.approval_date)
now := time.now_ns()
age_days := (now - approval) / (1000000000 * 86400)
```

### Debugging Policies

Add `--explain=full` to see decision trace:
```bash
opa eval --explain=full --data policy.rego --input data.json "data.governance.mycheck.deny"
```

## Resources

- **OPA Documentation:** https://www.openpolicyagent.org/docs/
- **Rego Language Guide:** https://www.openpolicyagent.org/docs/latest/policy-language/
- **OPA Playground:** https://play.openpolicyagent.org/ (test policies in browser)
- **Policy Library:** https://github.com/open-policy-agent/library

## Contributing New Policies

Potential policies to add:
- **GDPR compliance:** Data retention, anonymization checks
- **Model performance:** Precision/recall thresholds
- **Drift detection:** Alert if metrics degraded vs baseline
- **ISO 42001:** AI management system requirements
- **NIST AI RMF:** Framework-specific checks

To contribute:
1. Write policy in Rego
2. Add unit tests
3. Document in this README
4. Submit PR with example Kitfile showing violation
