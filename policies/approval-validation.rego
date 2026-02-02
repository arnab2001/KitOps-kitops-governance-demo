# Approval Validation Policy
# Enforces approval requirements and expiry for high-risk models
# EU AI Act Article 14 requires human oversight for high-risk AI systems

package governance.approvals

# Deny if high-risk model lacks approval
deny contains msg if {
    input.parameters.risk_level == "high"
    not input.parameters.approved_by
    msg := "High-risk models require explicit approval with approved_by field"
}

# Deny if high-risk model lacks approval date
deny contains msg if {
    input.parameters.risk_level == "high"
    not input.parameters.approval_date
    msg := "High-risk models require approval_date field"
}

# Deny if high-risk model approval is older than 90 days
deny contains msg if {
    input.parameters.risk_level == "high"
    
    # Parse approval date (RFC3339 format)
    approval := time.parse_rfc3339_ns(input.parameters.approval_date)
    now := time.now_ns()
    
    # Calculate age in days
    age_days := (now - approval) / (1000000000 * 86400)
    age_days > 90
    
    msg := sprintf("High-risk model approval expired (%d days old, maximum 90 days)", [round(age_days)])
}

# Helper function to check if approval is valid
approval_valid if {
    input.parameters.risk_level != "high"
}

approval_valid if {
    input.parameters.risk_level == "high"
    input.parameters.approved_by
    input.parameters.approval_date
    
    approval := time.parse_rfc3339_ns(input.parameters.approval_date)
    now := time.now_ns()
    age_days := (now - approval) / (1000000000 * 86400)
    age_days <= 90
}
