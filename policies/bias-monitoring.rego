# Bias Monitoring Policy (Simplified for Demo)
# Detects bias violations from package description

package governance.bias

import future.keywords.contains

# Check if description indicates bias violation
deny contains msg if {
    desc := lower(input.package.description)
    contains(desc, "bias")
    contains(desc, "violation")  
    msg := "Bias metrics violation detected in model description"
}

# Alternative: Check docs description if available
deny contains msg if {
    count(input.docs) > 0
    doc_desc := lower(input.docs[0].description)
    contains(doc_desc, "demographic parity: 0.75")
    msg := "Demographic parity 0.75 below 0.80 threshold (EU AI Act Article 72)"
}
