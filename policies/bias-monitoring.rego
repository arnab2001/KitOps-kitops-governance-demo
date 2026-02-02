# Bias Monitoring Policy
# EU AI Act Article 72 - Continuous monitoring of bias in high-risk AI systems
# Enforces fairness thresholds for demographic parity and equalized odds

package governance.bias

# Deny if demographic parity is below 0.80 (80% rule from disparate impact analysis)
deny contains msg if {
    input.parameters.risk_level == "high"
    
    dp := input.parameters.bias_metrics.demographic_parity
    dp < 0.80
    
    msg := sprintf(
        "Demographic parity %.2f below 0.80 threshold (EU AI Act Article 72 - bias monitoring required)",
        [dp]
    )
}

# Deny if equalized odds is below 0.85
deny contains msg if {
    input.parameters.risk_level == "high"
    
    eo := input.parameters.bias_metrics.equalized_odds
    eo < 0.85
    
    msg := sprintf(
        "Equalized odds %.2f below 0.85 threshold (EU AI Act Article 72 - fairness requirement)",
        [eo]
    )
}

# Deny if bias metrics are missing for high-risk models
deny contains msg if {
    input.parameters.risk_level == "high"
    not input.parameters.bias_metrics
    msg := "High-risk models require bias_metrics (demographic_parity and equalized_odds)"
}

# Deny if demographic_parity metric is missing
deny contains msg if {
    input.parameters.risk_level == "high"
    input.parameters.bias_metrics
    not input.parameters.bias_metrics.demographic_parity
    msg := "bias_metrics must include demographic_parity for high-risk models"
}

# Deny if equalized_odds metric is missing
deny contains msg if {
    input.parameters.risk_level == "high"
    input.parameters.bias_metrics
    not input.parameters.bias_metrics.equalized_odds
    msg := "bias_metrics must include equalized_odds for high-risk models"
}
