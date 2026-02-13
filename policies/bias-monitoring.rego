# Bias Monitoring Policy
# Uses structured governance metadata from model.parameters

package governance.bias

import future.keywords.contains

min_demographic_parity := 0.80
min_equalized_odds := 0.85

deny contains msg if {
    not is_number(input.model.parameters.governance.bias_metrics.demographic_parity)
    msg := "Missing or non-numeric governance.bias_metrics.demographic_parity in model.parameters"
}

deny contains msg if {
    not is_number(input.model.parameters.governance.bias_metrics.equalized_odds)
    msg := "Missing or non-numeric governance.bias_metrics.equalized_odds in model.parameters"
}

deny contains msg if {
    dp := input.model.parameters.governance.bias_metrics.demographic_parity
    dp < min_demographic_parity
    msg := sprintf(
        "Demographic parity %.2f below %.2f threshold (EU AI Act Article 72)",
        [dp, min_demographic_parity]
    )
}

deny contains msg if {
    eo := input.model.parameters.governance.bias_metrics.equalized_odds
    eo < min_equalized_odds
    msg := sprintf(
        "Equalized odds %.2f below %.2f threshold (EU AI Act Article 72)",
        [eo, min_equalized_odds]
    )
}
