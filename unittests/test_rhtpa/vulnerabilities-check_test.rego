package required_checks

import data.rhtpa as rhtpa
import data.curated_spdx_valid as curated
import future.keywords.if

test_warn_rhtpa_critical_vulnerabilities if {
    result := warn_rhtpa_critical_vulnerabilities with input as rhtpa
    count(result) == 1
    result[0].details.name == "rhtpa_critical_vulnerabilities"
    result[0].vulnerabilities_number == 1
    contains(result[0].msg, "critical")
}

test_warn_rhtpa_high_vulnerabilities if {
    result := warn_rhtpa_high_vulnerabilities with input as rhtpa
    count(result) == 1
    result[0].details.name == "rhtpa_high_vulnerabilities"
    # CVE-2024-0002 appears in both sources but is counted once (dedup)
    result[0].vulnerabilities_number == 2
    contains(result[0].msg, "high")
}

test_warn_rhtpa_medium_vulnerabilities if {
    result := warn_rhtpa_medium_vulnerabilities with input as rhtpa
    count(result) == 1
    result[0].details.name == "rhtpa_medium_vulnerabilities"
    result[0].vulnerabilities_number == 3
    contains(result[0].msg, "medium")
}

test_warn_rhtpa_low_vulnerabilities if {
    result := warn_rhtpa_low_vulnerabilities with input as rhtpa
    count(result) == 1
    result[0].details.name == "rhtpa_low_vulnerabilities"
    result[0].vulnerabilities_number == 2
    contains(result[0].msg, "low")
}

test_warn_rhtpa_critical_vulnerabilities_realworld if {
    result := warn_rhtpa_critical_vulnerabilities with input as curated
    count(result) == 1
    result[0].details.name == "rhtpa_critical_vulnerabilities"
    result[0].vulnerabilities_number == 2
}

test_warn_rhtpa_high_vulnerabilities_realworld if {
    result := warn_rhtpa_high_vulnerabilities with input as curated
    count(result) == 1
    result[0].details.name == "rhtpa_high_vulnerabilities"
    result[0].vulnerabilities_number == 6
}

test_warn_rhtpa_medium_vulnerabilities_realworld if {
    result := warn_rhtpa_medium_vulnerabilities with input as curated
    count(result) == 1
    result[0].details.name == "rhtpa_medium_vulnerabilities"
    result[0].vulnerabilities_number == 3
}

test_warn_rhtpa_low_vulnerabilities_realworld if {
    result := warn_rhtpa_low_vulnerabilities with input as curated
    count(result) == 1
    result[0].details.name == "rhtpa_low_vulnerabilities"
    result[0].vulnerabilities_number == 2
}

test_warn_rhtpa_no_vulnerabilities if {
    empty := {"providers": {"rhtpa": {"sources": {}}}}
    warn_rhtpa_critical_vulnerabilities == [] with input as empty
    warn_rhtpa_high_vulnerabilities == [] with input as empty
    warn_rhtpa_medium_vulnerabilities == [] with input as empty
    warn_rhtpa_low_vulnerabilities == [] with input as empty
}
