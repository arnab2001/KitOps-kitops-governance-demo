# License Compliance Policy
# Only validates the license field in package metadata

package governance.licenses

import future.keywords.in

# Define allowed licenses
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
    msg := sprintf("License '%s' not approved. Allowed: %v", [license, allowed_licenses])
}

# Deny if license missing
deny contains msg if {
    not input.package.license
    msg := "License field required"
}
