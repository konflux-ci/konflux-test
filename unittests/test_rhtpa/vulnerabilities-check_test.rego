package required_checks

import data.rhtpa as rhtpa
import data.curated_spdx_valid as curated
import future.keywords.if

test_warn_rhtpa_critical_vulnerabilities if {
    result := warn_rhtpa_critical_vulnerabilities with input as rhtpa
    count(result) == 1
    result[_].details.name == "rhtpa_critical_vulnerabilities"
    result[_].vulnerabilities_number == 1
    contains(result[_].msg, "critical")
    contains(result[_].msg, "source-a")
}

test_warn_rhtpa_high_vulnerabilities if {
    result := warn_rhtpa_high_vulnerabilities with input as rhtpa
    count(result) == 2
    some i, j
    result[i].details.name == "rhtpa_high_vulnerabilities"
    result[j].details.name == "rhtpa_high_vulnerabilities"
    result[i].vulnerabilities_number == 1
    result[j].vulnerabilities_number == 1
    contains(result[i].msg, "high")
    contains(result[j].msg, "high")
}

test_warn_rhtpa_medium_vulnerabilities if {
    result := warn_rhtpa_medium_vulnerabilities with input as rhtpa
    count(result) == 2
    some i, j
    result[i].details.name == "rhtpa_medium_vulnerabilities"
    result[j].details.name == "rhtpa_medium_vulnerabilities"
    contains(result[i].msg, "medium")
    contains(result[j].msg, "medium")
    # One source has 2 medium vulns (1 direct + 1 transitive), the other has 1 (transitive)
    nums := {result[k].vulnerabilities_number | some k; result[k].details.name == "rhtpa_medium_vulnerabilities"}
    nums == {1, 2}
}

test_warn_rhtpa_low_vulnerabilities if {
    result := warn_rhtpa_low_vulnerabilities with input as rhtpa
    count(result) == 2
    some i, j
    result[i].details.name == "rhtpa_low_vulnerabilities"
    result[j].details.name == "rhtpa_low_vulnerabilities"
    result[i].vulnerabilities_number == 1
    result[j].vulnerabilities_number == 1
    contains(result[i].msg, "low")
    contains(result[j].msg, "low")
}

test_warn_rhtpa_critical_vulnerabilities_realworld if {
    result := warn_rhtpa_critical_vulnerabilities with input as curated
    count(result) == 2
    some i, j
    result[i].details.name == "rhtpa_critical_vulnerabilities"
    result[j].details.name == "rhtpa_critical_vulnerabilities"
    result[i].vulnerabilities_number == 1
    result[j].vulnerabilities_number == 1
}

test_warn_rhtpa_high_vulnerabilities_realworld if {
    result := warn_rhtpa_high_vulnerabilities with input as curated
    count(result) == 2
    # osv-github has 2 high vulns, redhat-csaf has 4 (2 bind-libs + 1 openssl transitive + 1 postgresql)
    nums := {result[k].vulnerabilities_number | some k; result[k].details.name == "rhtpa_high_vulnerabilities"}
    nums == {2, 4}
}

test_warn_rhtpa_medium_vulnerabilities_realworld if {
    result := warn_rhtpa_medium_vulnerabilities with input as curated
    count(result) == 2
    # osv-github has 1 medium (transitive pip), redhat-csaf has 2 (1 openssl transitive + 1 postgresql)
    nums := {result[k].vulnerabilities_number | some k; result[k].details.name == "rhtpa_medium_vulnerabilities"}
    nums == {1, 2}
}

test_warn_rhtpa_low_vulnerabilities_realworld if {
    result := warn_rhtpa_low_vulnerabilities with input as curated
    count(result) == 1
    result[0].details.name == "rhtpa_low_vulnerabilities"
    result[0].vulnerabilities_number == 2
    contains(result[0].msg, "redhat-csaf")
}
