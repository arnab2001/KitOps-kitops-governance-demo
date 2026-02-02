# Quick Start Guide

## Installation (Required)

### Install OPA

The demo requires OPA (Open Policy Agent) to run policy evaluations.

**macOS:**
```bash
brew install opa
```

**Linux:**
```bash
curl -L https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -o /tmp/opa
sudo mv /tmp/opa /usr/local/bin/opa
sudo chmod +x /usr/local/bin/opa
```

**Verify installation:**
```bash
opa version
# Should output: Version: 0.x.x
```

### Optional: Install PyYAML (for advanced testing)
```bash
pip install pyyaml
```

---

## Running the Demo

Once OPA is installed:

```bash
cd demo
./run-demo.sh
```

**Demo duration:** ~30 seconds  
**Output:** Colored terminal output showing 5 scenarios with pass/fail results

---

## What You'll See

The demo will test **5 real scenarios**:

### ✅ Scenario 1: Compliant ModelKit
```
Testing: License Compliance (Apache-2.0)
  ✅ PASS

Testing: Approval Validation (18 days old)
  ✅ PASS

Testing: Bias Monitoring - EU AI Act Article 72 (DP: 0.96)
  ✅ PASS

✓ All policies passed - ModelKit approved for production
```

### ❌ Scenario 2: Bias Violation
```
Testing: Bias Monitoring - Demographic Parity (0.75)
  ❌ BLOCKED
  "Demographic parity 0.75 below 0.80 threshold (EU AI Act Article 72)"

✗ Deployment blocked - bias metrics below threshold
```

### ❌ Scenario 3: Expired Approval
```
Testing: Approval Validation (approval from Oct 2025)
  ❌ BLOCKED
  "High-risk model approval expired (124 days old, maximum 90 days)"

✗ Deployment blocked - approval expired
```

### ❌ Scenario 4: License Violation
```
Testing: License Compliance (GPL-3.0)
  ❌ BLOCKED
  "License 'GPL-3.0' not approved for production. Allowed licenses: ..."

✗ Deployment blocked - GPL license not approved
```

### ✅❌ Scenario 5: Security Checks
```
a) Clean scan (0 critical vulnerabilities)
  ✅ PASS - No critical vulnerabilities

b) Vulnerable scan (3 critical CVEs)
  ❌ BLOCKED
  "Found 3 critical vulnerabilities. All critical CVEs must be resolved..."
```

---

## Manual Testing (Alternative)

If you prefer to run tests one at a time:

### Test 1: License Policy
```bash
cd demo

# Should PASS (Apache-2.0 is allowed)
opa eval --data policies/license-compliance.rego \
         --input kitfile-examples/fraud-detection-compliant.yaml \
         --format pretty \
         "data.governance.licenses.deny"
```

**Expected output:** `[]` (empty array = passed)

### Test 2: Bias Policy
```bash
# Should DENY (demographic parity 0.75 < 0.80)
opa eval --data policies/bias-monitoring.rego \
         --input kitfile-examples/fraud-detection-bias-violation.yaml \
         --format pretty \
         "data.governance.bias.deny"
```

**Expected output:**
```
[
  "Demographic parity 0.75 below 0.80 threshold (EU AI Act Article 72 - bias monitoring required)"
]
```

---

## Troubleshooting

### "opa: command not found"
→ Install OPA first (see Installation section above)

### "cannot read file: Invalid YAML"
→ The demo uses YAML Kitfiles. OPA can't parse YAML natively for some operations. The demo script handles this automatically, but for manual testing you may need to convert YAML to JSON first.

### "undefined" in output
→ This actually means **PASS** - the policy found no violations

### Demo script permission denied
→ Make the script executable:
```bash
chmod +x demo/run-demo.sh
```

---

## Next Steps

1. ✅ Run `./run-demo.sh` to see all scenarios
2. ✅ Read `README.md` for detailed documentation
3. ✅ Explore individual policy files in `policies/`
4. ✅ Examine Kitfile examples in `kitfile-examples/`
5. ✅ Customize policies for your use case

---

## Presenting This Demo

**5-minute presentation flow:**

1. **[1 min]** Explain the problem: manual compliance can't keep up with AI deployment velocity
2. **[1 min]** Show compliant ModelKit passing all policies
3. **[2 min]** Demonstrate 3 violations: bias, expired approval, license
4. **[1 min]** Summarize: Spreadsheets = hope. Code = proof.

**Key talking points:**
- Policies run in milliseconds, not days
- Violations are automatically blocked
- Immutable audit trail for regulators
- EU AI Act compliance automated

---

**Questions?** See full documentation in `README.md`
