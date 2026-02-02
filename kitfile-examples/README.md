# Kitfile Examples

This directory contains sample ModelKit manifests demonstrating various compliance scenarios.

## Files

### ✅ `fraud-detection-compliant.yaml`
A **fully compliant** high-risk fraud detection model that passes all policies:
- **License:** Apache-2.0 (approved)
- **Approval:** Fresh (Jan 15, 2026 - only 18 days old)
- **Bias Metrics:** 
  - Demographic parity: 0.96 (≥ 0.80 ✅)
  - Equalized odds: 0.94 (≥ 0.85 ✅)
- **Risk Level:** High (requires all checks)

**Use case:** Demonstrates successful deployment path

---

### ❌ `fraud-detection-bias-violation.yaml`
**Non-compliant** - Violates EU AI Act bias requirements:
- **License:** Apache-2.0 ✅
- **Approval:** Valid ✅
- **Bias Metrics:** 
  - Demographic parity: **0.75** (< 0.80 ❌)
  - Equalized odds: 0.82 (< 0.85 ❌)

**Policy violation:** 
```
Demographic parity 0.75 below 0.80 threshold 
(EU AI Act Article 72 - bias monitoring required)
```

**Use case:** Demonstrates automatic bias detection and blocking

---

### ❌ `fraud-detection-expired-approval.yaml`
**Non-compliant** - Approval expired:
- **License:** Apache-2.0 ✅
- **Approval:** Oct 1, 2025 (**124 days old** - exceeds 90-day limit ❌)
- **Bias Metrics:** All passing ✅
- **Risk Level:** High

**Policy violation:**
```
High-risk model approval expired (124 days old, maximum 90 days)
```

**Use case:** Demonstrates automatic approval expiry enforcement

---

### ❌ `fraud-detection-license-violation.yaml`
**Non-compliant** - Unapproved license:
- **License:** **GPL-3.0** ❌ (not in allowed list)
- **Approval:** Valid ✅
- **Bias Metrics:** All passing ✅
- **Risk Level:** Medium

**Policy violation:**
```
License 'GPL-3.0' not approved for production. 
Allowed licenses: {"Apache-2.0", "MIT", "BSD-3-Clause", "Proprietary-Internal"}
```

**Use case:** Demonstrates license compliance enforcement

---

## Kitfile Structure

Every Kitfile follows this structure:

```yaml
manifestVersion: 1.0.0

package:
  name: model-name
  version: semver
  authors: [emails]
  license: SPDX-identifier

model:
  path: ./model-file
  framework: framework-name
  version: framework-version

code:
  - path: ./code-file.py

datasets:
  - path: ./dataset-file.parquet
    description: "Description"

docs:
  - path: ./documentation.md

parameters:
  risk_level: high|medium|low
  regulatory_scope: "Standard reference"
  bias_metrics:
    demographic_parity: 0.0-1.0
    equalized_odds: 0.0-1.0
  performance_metrics:
    precision: 0.0-1.0
    recall: 0.0-1.0
  approved_by: email
  approval_date: RFC3339 timestamp
```

## Key Governance Fields

### `risk_level`
- **high:** Requires approval, bias metrics, stricter security
- **medium:** Standard checks
- **low:** Minimal governance

### `bias_metrics`
Required for high-risk models:
- **demographic_parity:** Must be ≥ 0.80 (80% rule)
- **equalized_odds:** Must be ≥ 0.85

### `approval_date`
- Must be in RFC3339 format: `2026-01-15T10:00:00Z`
- For high-risk models: must be ≤ 90 days old

### `license`
Must be in allowed list:
- Apache-2.0
- MIT
- BSD-3-Clause
- Proprietary-Internal

## Testing Individual Kitfiles

```bash
# Test any Kitfile against a specific policy
opa eval --data ../policies/POLICY.rego \
         --input KITFILE.yaml \
         --format pretty \
         "data.governance.PACKAGE.deny"

# Example: Test compliant model against all policies
for policy in ../policies/*.rego; do
    echo "Testing $(basename $policy)..."
    opa eval --data "$policy" --input fraud-detection-compliant.yaml --format pretty 
done
```

## Creating Your Own Kitfiles

1. Start with `fraud-detection-compliant.yaml` as a template
2. Update package metadata (name, version, authors)
3. Update model/code/dataset paths to match your artifacts
4. Set appropriate `risk_level`
5. Provide required governance metadata based on risk level
6. Test against policies before using

**Tip:** Use `kit pack` to validate Kitfile syntax:
```bash
kit pack . -t myregistry.com/mymodel:v1
```
