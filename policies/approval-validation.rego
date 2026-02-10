# Approval & Bias Policy (Simplified for Demo)
# Parses metadata from package description field

package governance.approvals

import future.keywords.contains

# For demo purposes, check if description contains violation indicators
deny contains msg if {
    contains(lower(input.package.description), "expired")
    msg := "Model approval appears expired based on description"
}

deny contains msg if {
    contains(lower(input.package.description), "violation")
    not contains(lower(input.package.description), "license")  # Don't trigger on license violations
    msg := "Model contains policy violations based on description"
}
