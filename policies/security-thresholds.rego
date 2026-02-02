# Security Thresholds Policy
# Blocks deployment of ModelKits with critical vulnerabilities
# Integrates with Jozu Hub vulnerability scan results

package governance.security

# Deny if critical vulnerabilities exist with available fixes
deny contains msg if {
    critical := input.scan_results.vulnerability.critical_count
    critical > 0
    
    msg := sprintf(
        "Found %d critical vulnerabilities. All critical CVEs must be resolved before deployment",
        [critical]
    )
}

# Deny if high vulnerabilities exceed threshold
deny contains msg if {
    high := input.scan_results.vulnerability.high_count
    high > 5
    
    msg := sprintf(
        "Found %d high-severity vulnerabilities (threshold: 5). Remediate vulnerabilities before deployment",
        [high]
    )
}

# Deny if malware detected
deny contains msg if {
    input.scan_results.malware.threats_detected > 0
    threats := input.scan_results.malware.threat_types
    
    msg := sprintf(
        "Malware detected: %v. ModelKit cannot be deployed",
        [threats]
    )
}

# Deny if secrets found in code
deny contains msg if {
    secrets := input.scan_results.secrets.count
    secrets > 0
    
    msg := sprintf(
        "Found %d exposed secrets (API keys, credentials, tokens). Remove secrets before deployment",
        [secrets]
    )
}

# Allow if all security checks pass
allow contains true if {
    input.scan_results.vulnerability.critical_count == 0
    input.scan_results.vulnerability.high_count <= 5
    input.scan_results.malware.threats_detected == 0
    input.scan_results.secrets.count == 0
}
