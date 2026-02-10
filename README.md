# KitOps AI Governance Demo

**Real CI/CD policy gates** demonstrating automated AI governance with KitOps + OPA.

[![Governance Gate](https://github.com/YOUR-USERNAME/kitops-security/actions/workflows/modelkit-governance.yml/badge.svg)](https://github.com/YOUR-USERNAME/kitops-security/actions/workflows/modelkit-governance.yml)

## What This Shows

A GitHub Actions workflow that:
1. **Packs** a ModelKit with `kit pack` (real OCI artifact)
2. **Validates** against OPA policies (license, approval, bias, security)
3. **Blocks or Allows** deployment based on policy results
4. **Simulates** `kit push` and `cosign sign` for compliant models

## Quick Demo

### Option 1: Watch It Run
1. Fork this repo
2. Go to **Actions** → **AI Governance Gate** → **Run workflow**
3. See 4 scenarios execute in ~2 minutes

### Option 2: Make a Change
1. Edit `demo/kitfile-examples/fraud-detection-compliant.yaml`
2. Change `demographic_parity: 0.96` to `0.75`
3. Commit and push
4. Watch the workflow **block** the deployment

## What Gets Validated

| Policy | Enforces |
|--------|----------|
| **License** | Only Apache-2.0, MIT, BSD-3-Clause, Proprietary |
| **Approval** | High-risk models need approval < 90 days old |
| **Bias** | EU AI Act Article 72: DP ≥ 0.80, EO ≥ 0.85 |
| **Security** | 0 critical CVEs, max 5 high vulnerabilities |

## Files

```
.github/workflows/
  modelkit-governance.yml    # The workflow
demo/
  kitfile-examples/          # 4 scenarios (✅ pass, ❌ fail)
  policies/                  # 4 OPA Rego policies
  model-artifacts/           # Files to pack (model, code, docs)
```

## Local Testing

```bash
# Install OPA
brew install opa

# Test a policy
opa eval --data demo/policies/bias-monitoring.rego \
  --input demo/kitfile-examples/fraud-detection-bias-violation.yaml \
  --format pretty "data.governance.bias.deny"

# Should output: ["Demographic parity 0.75 below 0.80 threshold..."]
```

## Production Setup

To use this for real deployments:

1. **Add registry credentials:**
   ```yaml
   env:
     JOZU_TOKEN: ${{ secrets.JOZU_TOKEN }}
   ```

2. **Enable push:**
   ```yaml
   - name: Push to Registry
     run: kit push registry.jozu.ml/fraud:${{ github.sha }}
   ```

3. **Add signing:**
   ```yaml
   - name: Sign ModelKit
     run: cosign sign registry.jozu.ml/fraud:${{ github.sha }}
   ```

## Alignment with Blog

This demo proves the blog's core claims:
- ✅ **"Manual compliance can't match AI velocity"** - Policy runs in seconds
- ✅ **"Infrastructure refuses to deploy"** - Workflow fails on violations
- ✅ **"Regulations as code"** - EU AI Act Article 72 → Rego policy
- ✅ **"Cryptographic proof"** - SHA-256 hash from `kit pack`

---

**Built with:** [KitOps](https://kitops.org) · [OPA](https://openpolicyagent.org) · [Jozu Hub](https://jozu.com)
