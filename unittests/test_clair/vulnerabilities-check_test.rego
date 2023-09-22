package required_checks

import data.clair as clair

test_warn_critical_vulnerabilities {
    result := warn_critical_vulnerabilities with input as clair
    result[_].details.name == "clair_critical_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with critical vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_high_vulnerabilities {
    result := warn_high_vulnerabilities with input as clair
    result[_].details.name == "clair_high_vulnerabilities"
    result[_].vulnerabilities_number == 2
    result[_].msg == "Found packages with high vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_medium_vulnerabilities {
    result := warn_medium_vulnerabilities with input as clair
    result[_].details.name == "clair_medium_vulnerabilities"
    result[_].vulnerabilities_number == 3
    result[_].msg == "Found packages with medium vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_low_vulnerabilities {
    result := warn_low_vulnerabilities with input as clair
    result[_].details.name == "clair_low_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with low vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}

test_warn_unknown_vulnerabilities {
    result := warn_unknown_vulnerabilities with input as clair
    result[_].details.name == "clair_unknown_vulnerabilities"
    result[_].vulnerabilities_number == 1
    result[_].msg == "Found packages with unknown vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
}
