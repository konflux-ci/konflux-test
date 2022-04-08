package main

deny[msg] {
  rpms_with_critical_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Critical"}
  not count(rpms_with_critical_vulnerabilities) == 0

  msg = sprintf("The packages musn't have any critical vulnerabilities! Packages with critical vulnerabilities: %s", [concat(", ", rpms_with_critical_vulnerabilities)])
}

deny[msg] {
  rpms_with_high_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "High"}
  not count(rpms_with_high_vulnerabilities) == 0

  msg = sprintf("The packages musn't have any high vulnerabilities! Packages with high vulnerabilities: %s", [concat(", ", rpms_with_high_vulnerabilities)])
}

deny[msg] {
  rpms_with_medium_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Medium"}
  not count(rpms_with_medium_vulnerabilities) == 0

  msg = sprintf("The packages musn't have any medium vulnerabilities! Packages with medium vulnerabilities: %s", [concat(", ", rpms_with_medium_vulnerabilities)])
}

deny[msg] {
  rpms_with_low_vulnerabilities := {rpm.Name | rpm := input.data[_].Features[_]; count(rpm.Vulnerabilities) > 0; rpm.Vulnerabilities[_].Severity == "Low"}
  not count(rpms_with_low_vulnerabilities) == 0

  msg = sprintf("The packages musn't have any low vulnerabilities! Packages with low vulnerabilities: %s", [concat(", ", rpms_with_low_vulnerabilities)])
}

