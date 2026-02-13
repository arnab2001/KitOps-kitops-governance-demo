# Security Thresholds Policy
# Blocks deployment of ModelKits with critical vulnerabilities
# Uses structured governance metadata from model.parameters

package governance.security

import future.keywords.contains

deny contains msg if {
    not is_number(input.model.parameters.governance.scan_metrics.vulnerability.critical_count)
    msg := "Missing or non-numeric governance.scan_metrics.vulnerability.critical_count in model.parameters"
}

deny contains msg if {
    not is_number(input.model.parameters.governance.scan_metrics.vulnerability.high_count)
    msg := "Missing or non-numeric governance.scan_metrics.vulnerability.high_count in model.parameters"
}

deny contains msg if {
    not is_number(input.model.parameters.governance.scan_metrics.malware.threats_detected)
    msg := "Missing or non-numeric governance.scan_metrics.malware.threats_detected in model.parameters"
}

deny contains msg if {
    not is_number(input.model.parameters.governance.scan_metrics.secrets.count)
    msg := "Missing or non-numeric governance.scan_metrics.secrets.count in model.parameters"
}

deny contains msg if {
    critical := input.model.parameters.governance.scan_metrics.vulnerability.critical_count
    critical > 0
    msg := sprintf(
        "Found %d critical vulnerabilities. All critical CVEs must be resolved before deployment",
        [critical]
    )
}

deny contains msg if {
    high := input.model.parameters.governance.scan_metrics.vulnerability.high_count
    high > 5
    msg := sprintf(
        "Found %d high-severity vulnerabilities (threshold: 5). Remediate vulnerabilities before deployment",
        [high]
    )
}

deny contains msg if {
    threats_detected := input.model.parameters.governance.scan_metrics.malware.threats_detected
    threats_detected > 0
    msg := sprintf(
        "Malware scan reported %d detected threats. ModelKit cannot be deployed",
        [threats_detected]
    )
}

deny contains msg if {
    secrets := input.model.parameters.governance.scan_metrics.secrets.count
    secrets > 0
    msg := sprintf(
        "Found %d exposed secrets (API keys, credentials, tokens). Remove secrets before deployment",
        [secrets]
    )
}

allow contains true if {
    input.model.parameters.governance.scan_metrics.vulnerability.critical_count == 0
    input.model.parameters.governance.scan_metrics.vulnerability.high_count <= 5
    input.model.parameters.governance.scan_metrics.malware.threats_detected == 0
    input.model.parameters.governance.scan_metrics.secrets.count == 0
}
