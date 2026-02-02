# Mock Scan Results

These files simulate the output from Jozu Hub's 5 integrated security scanners.

## Files

### `clean-scan.json`
**Clean scan results** - Model passes all security checks:
- ✅ 0 critical vulnerabilities
- ✅ 2 high, 8 medium, 15 low vulnerabilities
- ✅ 0 malware threats detected
- ✅ 0 exposed secrets
- ✅ Apache-2.0 license detected
- ✅ SPDX 3.0 SBOM generated

**Use case:** Demonstrates successful security validation

---

### `vulnerable-scan.json`
**Vulnerable scan results** - Model fails security checks:
- ❌ **3 critical vulnerabilities:**
  - CVE-2025-1234 (sklearn 1.2.0 - arbitrary code execution)
  - CVE-2025-5678 (numpy 1.21.0 - buffer overflow)
  - CVE-2025-9012 (pillow 9.0.0 - remote code execution)
- ❌ 12 high-severity vulnerabilities
- ✅ 0 malware threats
- ✅ 0 exposed secrets

**Use case:** Demonstrates automatic CVE blocking

---

## Scan Result Structure

Jozu Hub produces scan results in this format:

```json
{
  "scan_results": {
    "vulnerability": {
      "critical_count": 0,
      "high_count": 2,
      "medium_count": 8,
      "low_count": 15,
      "critical_cves": [],
      "scan_timestamp": "2026-02-02T10:30:00Z",
      "scanner_version": "jozu-vuln-scanner-2.1.0"
    },
    "malware": {
      "threats_detected": 0,
      "threat_types": [],
      "scan_timestamp": "2026-02-02T10:30:05Z",
      "scanner_version": "jozu-malware-scanner-1.8.0"
    },
    "secrets": {
      "count": 0,
      "types_found": [],
      "scan_timestamp": "2026-02-02T10:30:10Z",
      "scanner_version": "jozu-secrets-scanner-3.0.1"
    },
    "license": {
      "primary_license": "Apache-2.0",
      "transitive_licenses": ["Apache-2.0", "MIT"],
      "issues_found": 0,
      "scan_timestamp": "2026-02-02T10:30:15Z"
    },
    "sbom": {
      "format": "SPDX-3.0",
      "total_components": 47,
      "scan_timestamp": "2026-02-02T10:30:20Z"
    }
  }
}
```

## Jozu Hub's 5 Scanners

### 1. Vulnerability Scanner
- Detects CVEs in dependencies (Python packages, system libs, model frameworks)
- Categorizes by severity: critical, high, medium, low
- Provides CVE IDs and descriptions
- **Policy enforcement:** Block if `critical_count > 0`

### 2. License Scanner
- Identifies licenses in code and dependencies
- Detects transitive license issues
- Flags GPL and copyleft licenses in proprietary code
- **Policy enforcement:** Block if license not in approved list

### 3. Malware Scanner
- Checks for code injection, backdoors, suspicious patterns
- Detects known malware signatures
- Analyzes model files for tampering
- **Policy enforcement:** Block if `threats_detected > 0`

### 4. Secrets Scanner
- Finds accidentally committed credentials
- Detects: API keys, AWS keys, database passwords, tokens
- Scans code, configs, and notebooks
- **Policy enforcement:** Block if `count > 0`

### 5. SBOM Generator
- Creates Software Bill of Materials in SPDX 3.0 format
- Lists all components with versions
- Enables supply chain tracking
- **Used for:** Audit trails and dependency analysis

## Testing with Mock Data

```bash
# Test security policy with clean scan
opa eval --data ../policies/security-thresholds.rego \
         --input clean-scan.json \
         --format pretty \
         "data.governance.security.deny"

# Should return: []  (PASS)

# Test security policy with vulnerable scan
opa eval --data ../policies/security-thresholds.rego \
         --input vulnerable-scan.json \
         --format pretty \
         "data.governance.security.deny"

# Should return: ["Found 3 critical vulnerabilities..."]  (BLOCKED)
```

## In Production

In a real deployment with Jozu Hub:

1. **Automatic Scanning:** Push ModelKit → Jozu Hub automatically scans
2. **Attestation Creation:** Each scanner produces a signed attestation
3. **Policy Query:** Before deployment, Jozu Hub queries OPA with scan results
4. **Decision:** OPA evaluates policies and returns allow/deny
5. **Enforcement:** Jozu Hub blocks deployment if policies fail
6. **Audit Log:** Decision recorded immutably with timestamp, user, violation

## Creating Your Own Mock Data

To test custom scenarios:

```json
{
  "scan_results": {
    "vulnerability": {
      "critical_count": 0,   // Change to test critical CVE blocking
      "high_count": 10,      // Change to test high CVE threshold
      "medium_count": 5,
      "low_count": 20
    },
    "malware": {
      "threats_detected": 1,  // Change to test malware blocking
      "threat_types": ["trojan", "backdoor"]
    },
    "secrets": {
      "count": 2,            // Change to test secrets blocking
      "types_found": ["aws_key", "api_token"]
    }
  }
}
```

Save as `custom-scan.json` and test:
```bash
opa eval --data ../policies/security-thresholds.rego \
         --input custom-scan.json \
         --format pretty \
         "data.governance.security.deny"
```

## Scan Result Integration

### With Kitfile
To combine Kitfile metadata with scan results:

```bash
# Merge YAML Kitfile with JSON scan results
python3 -c "
import yaml, json
with open('../kitfile-examples/fraud-detection-compliant.yaml') as f:
    kitfile = yaml.safe_load(f)
with open('clean-scan.json') as f:
    scan = json.load(f)
combined = {**kitfile, **scan}
json.dump(combined, open('combined-input.json', 'w'), indent=2)
"

# Test all policies with combined data
opa eval --data ../policies \
         --input combined-input.json \
         --format pretty \
         "data.governance"
```

This simulates what Jozu Hub does when evaluating policies.

## Understanding Real Scan Timings

In production, Jozu Hub scans execute:
- **Vulnerability scan:** ~30-60 seconds (depends on dependencies)
- **License scan:** ~10-20 seconds
- **Malware scan:** ~20-40 seconds
- **Secrets scan:** ~5-15 seconds
- **SBOM generation:** ~15-30 seconds

**Total scan time:** ~2-3 minutes per ModelKit

All scans run in parallel, so total wait time is ~60-90 seconds.

## Resources

- **Jozu Hub Docs:** https://jozu.com/docs/
- **SPDX Specification:** https://spdx.dev/
- **CVE Database:** https://cve.mitre.org/
- **OWASP Secrets Management:** https://owasp.org/www-community/vulnerabilities/Use_of_hard-coded_password
