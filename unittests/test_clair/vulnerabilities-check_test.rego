package required_checks

import data.clair as clair
import future.keywords.if

test_warn_critical_vulnerabilities if {
    result := warn_critical_vulnerabilities with input as clair
    result[_].details.name == "clair_critical_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with critical vulnerabilities associated with RHSA fixes. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_unpatched_critical_vulnerabilities if {
    result := warn_unpatched_critical_vulnerabilities with input as clair
    result[_].details.name == "clair_unpatched_critical_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with unpatched critical vulnerabilities. These vulnerabilities don't have a known fix at this time."
}

test_warn_high_vulnerabilities if {
    result := warn_high_vulnerabilities with input as clair
    result[_].details.name == "clair_high_vulnerabilities"
    result[_].vulnerabilities_number == 2
    result[_].msg == "Found packages with high vulnerabilities associated with RHSA fixes. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_unpatched_high_vulnerabilities if {
    result := warn_unpatched_high_vulnerabilities with input as clair
    result[_].details.name == "clair_unpatched_high_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with unpatched high vulnerabilities. These vulnerabilities don't have a known fix at this time."
}

test_warn_medium_vulnerabilities if {
    result := warn_medium_vulnerabilities with input as clair
    result[_].details.name == "clair_medium_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with medium vulnerabilities associated with RHSA fixes. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_unpatched_medium_vulnerabilities if {
    result := warn_unpatched_medium_vulnerabilities with input as clair
    result[_].details.name == "clair_unpatched_medium_vulnerabilities"
    result[_].vulnerabilities_number == 2
    result[_].msg == "Found packages with unpatched medium vulnerabilities. These vulnerabilities don't have a known fix at this time."
}

test_warn_low_vulnerabilities if {
    result := warn_low_vulnerabilities with input as clair
    result[_].details.name == "clair_low_vulnerabilities"
    result[_].vulnerabilities_number == 2
    result[_].msg == "Found packages with low/negligible vulnerabilities associated with RHSA fixes. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_unpatched_low_vulnerabilities if {
    result := warn_unpatched_low_vulnerabilities with input as clair
    result[_].details.name == "clair_unpatched_low_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with unpatched low/negligible vulnerabilities. These vulnerabilities don't have a known fix at this time."
}

test_warn_unknown_vulnerabilities if {
    result := warn_unknown_vulnerabilities with input as clair
    result[_].details.name == "clair_unknown_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with unknown vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_unpatched_unknown_vulnerabilities if {
    result := warn_unpatched_unknown_vulnerabilities with input as clair
    result[_].details.name == "clair_unpatched_unknown_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with unpatched unknown vulnerabilities. These vulnerabilities don't have a known fix at this time."
}
