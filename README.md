# KitOps Policy-as-Code Demo

**5-minute terminal demo** showing automated AI governance using KitOps + OPA

Based on the blog: *"Beyond the Spreadsheet: Implementing Policy-as-Code for AI Governance (EU AI Act & ISO 42001)"*

## What This Demo Shows

This demo demonstrates **real, working OPA policies** that enforce:
- ✅ License compliance (blocking GPL and unapproved licenses)
- ✅ Approval validation with 90-day expiry for high-risk models
- ✅ EU AI Act Article 72 bias monitoring (demographic parity & equalized odds)
- ✅ Security vulnerability thresholds (critical CVE blocking)

**No infrastructure required** - runs entirely on your local machine.

## Prerequisites

Install OPA (Open Policy Agent):

```bash
# macOS
brew install opa

# Linux
curl -L https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -o /usr/local/bin/opa
chmod +x /usr/local/bin/opa

# Verify installation
opa version
```

Optional (for manual testing):
```bash
# Python 3 with PyYAML (for Kitfile parsing)
pip install pyyaml
```

## Quick Start

Run the complete automated demo:

```bash
cd demo
./run-demo.sh
```

The script will:
1. ✅ Test a **compliant ModelKit** (all policies pass)
2. ❌ Test a **bias violation** (demographic parity 0.75 < 0.80)
3. ❌ Test an **expired approval** (>90 days old)
4. ❌ Test a **license violation** (GPL-3.0 not approved)
5. ✅❌ Test **security scans** (clean vs vulnerable)

**Expected runtime:** ~30 seconds

## Demo Structure

```
demo/
├── run-demo.sh                          # Main demo script (automated)
├── README.md                            # This file
│
├── kitfile-examples/                    # Sample ModelKits
│   ├── fraud-detection-compliant.yaml          # ✅ Passes all policies
│   ├── fraud-detection-bias-violation.yaml     # ❌ DP: 0.75 (fails)
│   ├── fraud-detection-expired-approval.yaml   # ❌ >90 days old
│   └── fraud-detection-license-violation.yaml  # ❌ GPL-3.0 license
│
├── policies/                            # OPA Rego policies
│   ├── license-compliance.rego          # Allowed licenses only
│   ├── approval-validation.rego         # 90-day expiry for high-risk
│   ├── bias-monitoring.rego             # EU AI Act Article 72
│   └── security-thresholds.rego         # CVE/malware/secrets blocking
│
└── mock-scan-results/                   # Simulated Jozu Hub scans
    ├── clean-scan.json                  # 0 critical vulnerabilities
    └── vulnerable-scan.json             # 3 critical CVEs
```

## Manual Testing (Step-by-Step)

If you want to test policies individually:

### 1. Test License Compliance

```bash
# ✅ Should PASS (Apache-2.0 is allowed)
opa eval --data policies/license-compliance.rego \
         --input kitfile-examples/fraud-detection-compliant.yaml \
         --format pretty \
         "data.governance.licenses.deny"

# ❌ Should DENY (GPL-3.0 not allowed)
opa eval --data policies/license-compliance.rego \
         --input kitfile-examples/fraud-detection-license-violation.yaml \
         --format pretty \
         "data.governance.licenses.deny"
```

**Expected output (PASS):**
```
[]
```

**Expected output (DENY):**
```
[
  "License 'GPL-3.0' not approved for production. Allowed licenses: {...}"
]
```

### 2. Test Bias Monitoring (EU AI Act Article 72)

```bash
# ✅ Should PASS (DP: 0.96 >= 0.80)
opa eval --data policies/bias-monitoring.rego \
         --input kitfile-examples/fraud-detection-compliant.yaml \
         --format pretty \
         "data.governance.bias.deny"

# ❌ Should DENY (DP: 0.75 < 0.80)
opa eval --data policies/bias-monitoring.rego \
         --input kitfile-examples/fraud-detection-bias-violation.yaml \
         --format pretty \
         "data.governance.bias.deny"
```

**Expected output (DENY):**
```
[
  "Demographic parity 0.75 below 0.80 threshold (EU AI Act Article 72 - bias monitoring required)"
]
```

### 3. Test Approval Expiry

```bash
# ❌ Should DENY (approval from Oct 2025, >90 days ago)
opa eval --data policies/approval-validation.rego \
         --input kitfile-examples/fraud-detection-expired-approval.yaml \
         --format pretty \
         "data.governance.approvals.deny"
```

**Expected output (DENY):**
```
[
  "High-risk model approval expired (124 days old, maximum 90 days)"
]
```

### 4. Test Security Thresholds

```bash
# ✅ Should PASS (0 critical vulnerabilities)
opa eval --data policies/security-thresholds.rego \
         --input mock-scan-results/clean-scan.json \
         --format pretty \
         "data.governance.security.deny"

# ❌ Should DENY (3 critical CVEs)
opa eval --data policies/security-thresholds.rego \
         --input mock-scan-results/vulnerable-scan.json \
         --format pretty \
         "data.governance.security.deny"
```

## Understanding the Demo Flow

### The Problem (from the blog)
- Models deploy hourly, compliance checks happen weekly
- Manual spreadsheets can't prove what's running in production
- EU AI Act requires continuous monitoring and multi-year audit trails

### The Solution (demonstrated here)
```
[Data Scientist] → [ModelKit] → [Jozu Hub Scanning]
                                        ↓
                                    [OPA Policy Check]
                                    ↙              ↘
                              [ALLOW]            [DENY + Reason]
                                ↓                    ↓
                          [Production]         [Blocked + Logged]
```

### What Each Policy Enforces

1. **License Compliance** (`license-compliance.rego`)
   - Only approved licenses (Apache-2.0, MIT, BSD-3-Clause, Proprietary-Internal)
   - Blocks GPL and other copyleft licenses

2. **Approval Validation** (`approval-validation.rego`)
   - High-risk models require explicit approval
   - Approvals expire after 90 days
   - Automatic re-approval enforcement

3. **Bias Monitoring** (`bias-monitoring.rego`)
   - EU AI Act Article 72 compliance
   - Demographic parity ≥ 0.80 (80% rule)
   - Equalized odds ≥ 0.85

4. **Security Thresholds** (`security-thresholds.rego`)
   - Zero critical vulnerabilities allowed
   - Max 5 high-severity vulnerabilities
   - Blocks malware and exposed secrets

## Key Demo Points to Emphasize

### 1. **Tamper-Proof Packaging**
Every Kitfile gets a SHA-256 hash. Change one line → hash changes → provable versioning.

### 2. **Automated Gates**
Policies run in milliseconds. No manual reviews, no waiting for committee approval.

### 3. **Immutable Audit Trail**
Every policy decision is logged with:
- Timestamp
- User who attempted deployment
- Model version and hash
- Exact policy violation or approval

### 4. **Regulations as Code**
EU AI Act Article 72 → Rego policy that blocks deployments automatically.

## Demo Script (5-Minute Walkthrough)

Use this script when presenting:

---

**[0:00-0:30] Introduction**
> "We're about to see how policy-as-code stops non-compliant AI models from reaching production. No manual reviews, no spreadsheets—just automated enforcement."

**[0:30-1:30] Scenario 1: Compliant Model**
```bash
./run-demo.sh
```
> "This is a fraud detection model. It has Apache-2.0 license, fresh approval, and bias metrics of 0.96. Watch all policies pass..."

**[1:30-2:30] Scenario 2: Bias Violation**
> "Now the same model, but demographic parity dropped to 0.75—below the EU AI Act threshold of 0.80 for the 80% rule. Watch it get blocked..."

**[2:30-3:30] Scenario 3: Expired Approval**
> "This approval is from October 2025—over 90 days ago. High-risk models need re-approval. See how policy catches it automatically..."

**[3:30-4:15] Scenario 4: License & Security**
> "GPL license gets blocked. Critical vulnerabilities get blocked. All automated, millisecond evaluation."

**[4:15-5:00] Summary**
> "This is governance as infrastructure. Violations can't bypass the system. Spreadsheets = hope. Code = proof. Regulators want proof."

---

## Customizing Policies

All policies are in `policies/*.rego`. You can:

1. **Change thresholds:**
   ```rego
   # In bias-monitoring.rego, change threshold:
   dp < 0.80  # Change to 0.85 for stricter enforcement
   ```

2. **Add new allowed licenses:**
   ```rego
   # In license-compliance.rego:
   allowed_licenses := {
       "Apache-2.0",
       "MIT",
       "BSD-3-Clause",
       "Proprietary-Internal",
       "ISC"  # Add new license
   }
   ```

3. **Modify approval expiry:**
   ```rego
   # In approval-validation.rego:
   age_days > 90  # Change to 60 or 120 days
   ```

## Next Steps

After running this demo:

1. ✅ Understand the core workflow (ModelKit → Scan → Policy → Allow/Deny)
2. ✅ See how regulations become executable code
3. ✅ Explore writing your own policies for your specific compliance needs

**Production Implementation:**
- Week 1-2: Set up Jozu Hub and OPA
- Week 3-4: Create Kitfiles for 2-3 pilot models
- Week 5: Run in audit mode (log but don't block)
- Week 6: Switch to enforcement mode

## Resources

- **Blog:** Read the full implementation guide in `../blog.md`
- **KitOps Docs:** https://kitops.org/docs/
- **Jozu Hub:** https://jozu.com/
- **OPA Docs:** https://www.openpolicyagent.org/docs/
- **EU AI Act:** https://artificialintelligenceact.eu/

## Troubleshooting

**Problem:** `opa: command not found`
```bash
# Install OPA first
brew install opa  # macOS
```

**Problem:** Demo script fails to parse YAML
```bash
# Install PyYAML
pip install pyyaml
```

**Problem:** Policy shows "undefined"
- This means the policy passed (no violations found)
- Empty array `[]` also means passed

**Problem:** Want to see more verbose output
```bash
# Add --explain=full to any opa eval command
opa eval --explain=full --data policies/... --input ...
```

## Contributing

Found an issue or want to add more policies? 
- Bias mitigation for different fairness metrics
- GDPR data retention policies
- Model performance degradation detection
- Other regulatory frameworks (NIST AI RMF, ISO 42001)

---

**Built with:** KitOps, OPA, and a commitment to making AI governance automated and auditable.
