package required_checks

import data.clair as clair

test_violation_critical_vulnerabilities {
    result := violation_critical_vulnerabilities with input as clair
    result[_].details.name == "clair_critical_vulnerabilities"
    result[_].msg == "Found packages with critical vulnerabilities: pip"
}

test_violation_high_vulnerabilities {
    result := violation_high_vulnerabilities with input as clair
    result[_].details.name == "clair_high_vulnerabilities"
    result[_].msg == "Found packages with high vulnerabilities: zlib"
}

test_violation_medium_vulnerabilities {
    result := violation_medium_vulnerabilities with input as clair
    result[_].details.name == "clair_medium_vulnerabilities"
    result[_].msg == "Found packages with medium vulnerabilities: pip"
}

test_violation_low_vulnerabilities {
    result := violation_low_vulnerabilities with input as clair
    result[_].details.name == "clair_low_vulnerabilities"
    result[_].msg == "Found packages with low vulnerabilities: pip"
}
