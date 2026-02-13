# KitOps AI Governance Demo

Real CI/CD governance gates with **KitOps + OPA + Cosign attestations**.

[![Governance Gate](https://github.com/YOUR-USERNAME/kitops-security/actions/workflows/main.yml/badge.svg)](https://github.com/YOUR-USERNAME/kitops-security/actions/workflows/main.yml)

## What This Shows

This workflow implements a hybrid governance model:
1. **Pack** a ModelKit with `kit pack`.
2. **Validate** governance policy rules from structured `model.parameters.governance` metadata.
3. **Block in CI** when any policy fails.
4. **Push and attest** with Cosign only when all policies pass.

This keeps GitHub Actions easy to demo while still producing signed evidence for downstream policy engines in Jozu Hub.

## Governance Metadata Contract

OPA policies now read governance inputs from Kitfile metadata, not free-text descriptions.

```yaml
model:
  parameters:
    governance:
      risk_level: high
      regulatory_scope: "EU AI Act Article 12"
      bias_metrics:
        demographic_parity: 0.96
        equalized_odds: 0.94
      performance_metrics:
        precision: 0.94
        recall: 0.89
      approval:
        approved_by: alice@company.com
        approval_date: "2026-01-15T10:00:00Z"
      scan_metrics:
        vulnerability:
          critical_count: 0
          high_count: 2
        malware:
          threats_detected: 0
        secrets:
          count: 0
```

## Quick Demo

1. Fork this repository.
2. Go to **Actions** -> **AI Governance Gate** -> **Run workflow**.
3. Watch 4 matrix scenarios run in parallel.

Expected outcomes:

| Scenario | Result | Primary reason |
|---|---|---|
| Pass - Compliant Model | PASS | All policies pass |
| Block - Bias Violation | FAIL | `demographic_parity` below `0.80` |
| Block - Expired Approval | FAIL | `approval_date` older than 90 days |
| Block - License Violation | FAIL | `GPL-3.0` not in allowed license set |

Note: the license violation scenario also carries `high_count: 8` to exercise the security policy path.

## Attestation Evidence

For each matrix job, the workflow writes a machine-readable summary artifact:
- `policy-results/policy-summary.json`

For PASS scenarios, the workflow creates a keyless attestation:

```bash
cosign attest --yes \
  --predicate policy-results/policy-summary.json \
  --type "https://jozu.com/attestations/kitops-governance/v1" \
  jozu.ml/arnabchat2001/kitops-governance-demo:<git-sha>
```

The predicate includes:
- scenario name
- git SHA
- policy deny arrays per control (license/approval/bias/security)
- extracted governance scan metrics

## Repository Layout

```
.github/workflows/
  main.yml                     # pack -> validate -> push -> attest
kitfile-examples/
  *.yaml                       # four governance scenarios
policies/
  *.rego                       # OPA policy modules
model-artifacts/
  Kitfile, model.py, inference.py, MODEL_CARD.md
```

## Local Policy Check

```bash
brew install opa

opa eval --data policies/bias-monitoring.rego \
  --input kitfile-examples/fraud-detection-bias-violation.yaml \
  --format pretty "data.governance.bias.deny"
```

## Production Requirements

1. Set GitHub secrets:
   - `JOZU_USERNAME`
   - `JOZU_PASSWORD`
2. Keep workflow permissions:
   - `contents: read`
   - `id-token: write` (for keyless Cosign)
3. Point image references at your own Jozu repository.

---

Built with [KitOps](https://kitops.org), [OPA](https://openpolicyagent.org), and [Jozu Hub](https://jozu.com).
