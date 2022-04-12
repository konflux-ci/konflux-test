package required_checks

violation_critical_vulnerabilities[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_critical_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Critical"}
  not count(rpms_with_critical_vulnerabilities) == 0

  name := "clair_critical_vulnerabilities"
  msg = sprintf("Found packages with critical vulnerabilities: %s", [concat(", ", rpms_with_critical_vulnerabilities)])
  description := "The image musn't contain packages that have critical severity vulnerabilities."
  url := "https://source.redhat.com/groups/public/product-security/content/product_security_folder/understanding_red_hat_security_vulnerabilities_10pdf"
}

violation_high_vulnerabilities[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_high_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "High"}
  not count(rpms_with_high_vulnerabilities) == 0

  name := "clair_high_vulnerabilities"
  msg = sprintf("Found packages with high vulnerabilities: %s", [concat(", ", rpms_with_high_vulnerabilities)])
  description := "The image musn't contain packages that have high severity vulnerabilities."
  url := "https://source.redhat.com/groups/public/product-security/content/product_security_folder/understanding_red_hat_security_vulnerabilities_10pdf"
}

violation_medium_vulnerabilities[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_medium_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Medium"}
  not count(rpms_with_medium_vulnerabilities) == 0

  name := "clair_medium_vulnerabilities"
  msg = sprintf("Found packages with medium vulnerabilities: %s", [concat(", ", rpms_with_medium_vulnerabilities)])
  description := "The image musn't contain packages that have medium severity vulnerabilities."
  url := "https://source.redhat.com/groups/public/product-security/content/product_security_folder/understanding_red_hat_security_vulnerabilities_10pdf"
}

violation_low_vulnerabilities[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_low_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Low"}
  not count(rpms_with_low_vulnerabilities) == 0

  name := "clair_low_vulnerabilities"
  msg = sprintf("Found packages with low vulnerabilities: %s", [concat(", ", rpms_with_low_vulnerabilities)])
  description := "The image musn't contain packages that have low severity vulnerabilities."
  url := "https://source.redhat.com/groups/public/product-security/content/product_security_folder/understanding_red_hat_security_vulnerabilities_10pdf"
}

