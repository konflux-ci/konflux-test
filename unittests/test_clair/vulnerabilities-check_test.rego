package required_checks

import data.clair as clair

test_violation_critical_vulnerabilities {
    result := violation_critical_vulnerabilities with input as clair
    result[_].details.name == "clair_critical_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with critical vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_violation_high_vulnerabilities {
    result := violation_high_vulnerabilities with input as clair
    result[_].details.name == "clair_high_vulnerabilities"
    result[_].vulnerabilities_number == 2
    result[_].msg == "Found packages with high vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_violation_medium_vulnerabilities {
    result := violation_medium_vulnerabilities with input as clair
    result[_].details.name == "clair_medium_vulnerabilities"
    result[_].vulnerabilities_number == 3
    result[_].msg == "Found packages with medium vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_violation_low_vulnerabilities {
    result := violation_low_vulnerabilities with input as clair
    result[_].details.name == "clair_low_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with low vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}
