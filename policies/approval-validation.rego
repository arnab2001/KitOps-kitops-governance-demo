# Approval Validation Policy
# Uses structured governance metadata from model.parameters

package governance.approvals

import future.keywords.contains

max_approval_age_days := 90
day_ns := 24 * 60 * 60 * 1000000000
max_approval_age_ns := max_approval_age_days * day_ns

deny contains msg if {
    not is_string(input.model.parameters.governance.approval.approved_by)
    msg := "Missing governance.approval.approved_by in model.parameters"
}

deny contains msg if {
    not is_string(input.model.parameters.governance.approval.approval_date)
    msg := "Missing governance.approval.approval_date in model.parameters"
}

approval_timestamp_ns(date) = ns if {
    ns := time.parse_rfc3339_ns(date)
}

deny contains msg if {
    date := input.model.parameters.governance.approval.approval_date
    not approval_timestamp_ns(date)
    msg := sprintf(
        "Invalid RFC3339 timestamp for governance.approval.approval_date: %s",
        [date]
    )
}

deny contains msg if {
    date := input.model.parameters.governance.approval.approval_date
    approval_ns := approval_timestamp_ns(date)
    age_ns := time.now_ns() - approval_ns
    age_ns > max_approval_age_ns
    age_days := floor(age_ns / day_ns)
    msg := sprintf(
        "Approval date %s is %v days old (max allowed: %d days)",
        [date, age_days, max_approval_age_days]
    )
}
