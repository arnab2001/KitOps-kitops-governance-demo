# Jozu Hub and Cosign Setup

## Required Secrets

Add these GitHub Actions secrets:

- `JOZU_USERNAME`
- `JOZU_PASSWORD`

Repository settings path:
`Settings -> Secrets and variables -> Actions`

## Required Workflow Permissions

Your workflow must include:

```yaml
permissions:
  contents: read
  id-token: write
```

`id-token: write` is required for keyless Cosign attestation in GitHub Actions.

## Authentication Flow in CI

PASS scenarios run this sequence:

1. `kit login jozu.ml`
2. `kit push ...:<git-sha>` and `kit push ...:latest`
3. `cosign login jozu.ml`
4. `cosign attest --predicate policy-results/policy-summary.json ...:<git-sha>`

FAIL scenarios:
- skip push
- skip attestation
- end as blocked in CI

## Verify Setup

1. Run **AI Governance Gate** from Actions.
2. Open the `Pass - Compliant Model` job.
3. Confirm these steps are green:
   - `Push to Jozu Hub`
   - `Attest Governance Results`

## Attestation Payload

Attestation predicate is generated from `policy-results/policy-summary.json` and includes:
- scenario
- git SHA
- policy decisions (deny arrays)
- governance scan metrics

This is the evidence payload downstream policy engines can verify.

## Inspecting Attestations

In CI logs, verify `cosign attest` ran against:
`jozu.ml/arnabchat2001/kitops-governance-demo:<git-sha>`

In Jozu Hub / policy-engine integrations, inspect attestations attached to that same tag and check predicate type:
`https://jozu.com/attestations/kitops-governance/v1`

## Troubleshooting

**Authentication required**
- Re-check `JOZU_USERNAME` and `JOZU_PASSWORD` values.
- Confirm account can push to the target repository.

**Cosign attestation fails with OIDC error**
- Ensure workflow has `id-token: write`.
- Ensure the runner can reach Sigstore endpoints.

**Repository does not exist**
- Create `kitops-governance-demo` in Jozu Hub first, or update workflow image path.
