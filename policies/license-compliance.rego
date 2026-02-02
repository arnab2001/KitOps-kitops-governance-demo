# License Compliance Policy
# Ensures only approved licenses are used in production ModelKits
# Blocks GPL and other copyleft licenses that may conflict with proprietary code

package governance.licenses

import future.keywords.in

# Define allowed licenses for production deployment
allowed_licenses := {
    "Apache-2.0",
    "MIT", 
    "BSD-3-Clause",
    "Proprietary-Internal"
}

# Deny if license not in allowed set
deny contains msg if {
    license := input.package.license
    not license in allowed_licenses
    msg := sprintf("License '%s' not approved for production. Allowed licenses: %v", [license, allowed_licenses])
}

# Additional check: Deny if license field is missing
deny contains msg if {
    not input.package.license
    msg := "License field is required in package metadata"
}
