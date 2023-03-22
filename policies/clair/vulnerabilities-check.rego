package required_checks

violation_critical_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_critical_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Critical"}
  not count(rpms_with_critical_vulnerabilities) == 0

  name := "clair_critical_vulnerabilities"
  vulns_num = count(rpms_with_critical_vulnerabilities)
  msg := "Found packages with critical vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description = sprintf("Packages found: %s", [concat(", ", rpms_with_critical_vulnerabilities)])
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

violation_high_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_high_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "High"}
  not count(rpms_with_high_vulnerabilities) == 0

  name := "clair_high_vulnerabilities"
  vulns_num = count(rpms_with_high_vulnerabilities)
  msg := "Found packages with high vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description = sprintf("Packages found: %s", [concat(", ", rpms_with_high_vulnerabilities)])
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

violation_medium_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_medium_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Medium"}
  not count(rpms_with_medium_vulnerabilities) == 0

  name := "clair_medium_vulnerabilities"
  vulns_num = count(rpms_with_medium_vulnerabilities)
  msg := "Found packages with medium vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description = sprintf("Packages found: %s", [concat(", ", rpms_with_medium_vulnerabilities)])
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

violation_low_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_low_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Low"}
  not count(rpms_with_low_vulnerabilities) == 0

  name := "clair_low_vulnerabilities"
  vulns_num = count(rpms_with_low_vulnerabilities)
  msg := "Found packages with low vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description = sprintf("Packages found: %s", [concat(", ", rpms_with_low_vulnerabilities)])
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}
