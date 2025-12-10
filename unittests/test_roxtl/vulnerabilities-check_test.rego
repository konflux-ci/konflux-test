package required_checks

import data.roxctl_new as roxctl
import future.keywords.if

test_warn_critical_vulnerabilities if {
    result := warn_roxctl_critical_vulnerabilities with input as roxctl
    count(result) > 0
    result[_].details.name == "roxctl_critical_vulnerabilities"
    result[_].msg == "Found components with critical vulnerabilities that have available fixes. Consider updating to a newer version of those components."
}

test_warn_unpatched_critical_vulnerabilities if {
    result := warn_roxctl_unpatched_critical_vulnerabilities with input as roxctl
    count(result) > 0
    result[_].details.name == "roxctl_unpatched_critical_vulnerabilities"
    result[_].msg == "Found components with unpatched critical vulnerabilities. These vulnerabilities don't have a known fix at this time."
}

test_warn_high_vulnerabilities if {
    result := warn_roxctl_high_vulnerabilities with input as roxctl
    count(result) > 0
    result[_].details.name == "roxctl_high_vulnerabilities"
    result[_].msg == "Found components with high vulnerabilities that have available fixes. Consider updating to a newer version of those components."
}

test_warn_unpatched_high_vulnerabilities if {
    result := warn_roxctl_unpatched_high_vulnerabilities with input as roxctl
    count(result) > 0
    result[_].details.name == "roxctl_unpatched_high_vulnerabilities"
    result[_].msg == "Found components with unpatched high vulnerabilities. These vulnerabilities don't have a known fix at this time."    
}

test_warn_medium_vulnerabilities if {
    result := warn_roxctl_medium_vulnerabilities with input as roxctl
    count(result) > 0
    result[_].details.name == "roxctl_medium_vulnerabilities"
    result[_].msg == "Found components with medium vulnerabilities that have available fixes. Consider updating to a newer version of those components."
}

test_warn_unpatched_medium_vulnerabilities if {
    result := warn_roxctl_unpatched_medium_vulnerabilities with input as roxctl
    count(result) > 0
    result[_].details.name == "roxctl_unpatched_medium_vulnerabilities"
    result[_].msg == "Found components with unpatched medium vulnerabilities. These vulnerabilities don't have a known fix at this time."    
}

test_warn_low_vulnerabilities if {
    result := warn_roxctl_low_vulnerabilities with input as roxctl
    count(result) > 0
    result[_].details.name == "roxctl_low_vulnerabilities"
    result[_].msg == "Found components with low vulnerabilities that have available fixes. Consider updating to a newer version of those components."
}

test_warn_unpatched_low_vulnerabilities if {
    result := warn_roxctl_unpatched_low_vulnerabilities with input as roxctl
    count(result) > 0
    result[_].details.name == "roxctl_unpatched_low_vulnerabilities"
    result[_].msg == "Found components with unpatched low vulnerabilities. These vulnerabilities don't have a known fix at this time."    
}
