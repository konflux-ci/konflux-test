package required_checks

# function to get mapping {rpm: set of vulnerabilities names}; duplicated vulnerabilities are removed
get_patched_vulnerabilities(input_data, severity) := vulnerabilities {
  vulnerabilities := [{"name": rpm.Name, "version": rpm.Version, "vulnerabilities": vuln} |
    rpm := input_data.data[_].Features[_]
    vuln := {v.Name | v:=rpm.Vulnerabilities[_]; v.Severity == severity; v.FixedBy != ""; contains(v.Link,"RHSA")}
    count(vuln) > 0
  ]
}

# function to get mapping {rpm: set of vulnerabilities names}; duplicated vulnerabilities are removed
get_unpatched_vulnerabilities(input_data, severity) := vulnerabilities {
  vulnerabilities := [{"name": rpm.Name, "version": rpm.Version, "vulnerabilities": vuln} |
    rpm := input_data.data[_].Features[_]
    vuln := {v.Name | v:=rpm.Vulnerabilities[_]; v.Severity == severity; any([v.FixedBy == "", contains(v.Link,"RHSA") == false ])}
    count(vuln) > 0
  ]
}


# function returns count of all vulnerabilities
count_vulnerabilities(vulnerabilities) := cnt {
  cnt := sum([count(v.vulnerabilities) | v:=vulnerabilities[_]])
}

# function generates description with RPMs and their vulnerabilities
generate_description(vulnerabilities) := dsc {
  dsc := sprintf("Vulnerabilities found: %s", [concat(", ",
                   [sprintf("%s-%s (%s)", [v.name, v.version, concat(", ", v.vulnerabilities)]) | v := vulnerabilities[_]]
                 )])
}

warn_critical_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_critical_vulnerabilities := get_patched_vulnerabilities(input, "Critical")
  not count(rpms_with_critical_vulnerabilities) == 0

  name := "clair_critical_vulnerabilities"
  vulns_num := count_vulnerabilities(rpms_with_critical_vulnerabilities)
  msg := "Found packages with critical vulnerabilities associated with RHSA fixes. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description := generate_description(rpms_with_critical_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_unpatched_critical_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_unpatched_critical_vulnerabilities := get_unpatched_vulnerabilities(input, "Critical")
  not count(rpms_with_unpatched_critical_vulnerabilities) == 0

  name := "clair_unpatched_critical_vulnerabilities"
  vulns_num := count_vulnerabilities(rpms_with_unpatched_critical_vulnerabilities)
  msg := "Found packages with unpatched critical vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := generate_description(rpms_with_unpatched_critical_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_high_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_high_vulnerabilities := get_patched_vulnerabilities(input, "High")
  not count(rpms_with_high_vulnerabilities) == 0

  name := "clair_high_vulnerabilities"
  vulns_num = count_vulnerabilities(rpms_with_high_vulnerabilities)
  msg := "Found packages with high vulnerabilities associated with RHSA fixes. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description := generate_description(rpms_with_high_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_unpatched_high_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_unpatched_high_vulnerabilities := get_unpatched_vulnerabilities(input, "High")
  not count(rpms_with_unpatched_high_vulnerabilities) == 0

  name := "clair_unpatched_high_vulnerabilities"
  vulns_num = count_vulnerabilities(rpms_with_unpatched_high_vulnerabilities)
  msg := "Found packages with unpatched high vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := generate_description(rpms_with_unpatched_high_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_medium_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_medium_vulnerabilities := get_patched_vulnerabilities(input, "Medium")
  not count(rpms_with_medium_vulnerabilities) == 0

  name := "clair_medium_vulnerabilities"
  vulns_num := count_vulnerabilities(rpms_with_medium_vulnerabilities)
  msg := "Found packages with medium vulnerabilities associated with RHSA fixes. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description := generate_description(rpms_with_medium_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_unpatched_medium_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_unpatched_medium_vulnerabilities := get_unpatched_vulnerabilities(input, "Medium")
  not count(rpms_with_unpatched_medium_vulnerabilities) == 0

  name := "clair_unpatched_medium_vulnerabilities"
  vulns_num := count_vulnerabilities(rpms_with_unpatched_medium_vulnerabilities)
  msg := "Found packages with unpatched medium vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := generate_description(rpms_with_unpatched_medium_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_low_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_low_vulnerabilities := get_patched_vulnerabilities(input, "Low")
  rpms_with_negligible_vulnerabilities := get_patched_vulnerabilities(input, "Negligible")
  rpms_with_low_neg_vulnerabilities = array.concat(rpms_with_low_vulnerabilities, rpms_with_negligible_vulnerabilities)
  not count(rpms_with_low_neg_vulnerabilities) == 0

  name := "clair_low_vulnerabilities"
  vulns_num := count_vulnerabilities(rpms_with_low_neg_vulnerabilities)
  msg := "Found packages with low/negligible vulnerabilities associated with RHSA fixes. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description := generate_description(rpms_with_low_neg_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_unpatched_low_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_unpatched_low_vulnerabilities := get_unpatched_vulnerabilities(input, "Low")
  rpms_with_unpatched_negligible_vulnerabilities := get_unpatched_vulnerabilities(input, "Negligible")
  rpms_with_unpatched_low_neg_vulnerabilities = array.concat(rpms_with_unpatched_low_vulnerabilities, rpms_with_unpatched_negligible_vulnerabilities)
  not count(rpms_with_unpatched_low_neg_vulnerabilities) == 0

  name := "clair_unpatched_low_vulnerabilities"
  vulns_num := count_vulnerabilities(rpms_with_unpatched_low_neg_vulnerabilities)
  msg := "Found packages with unpatched low/negligible vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := generate_description(rpms_with_unpatched_low_neg_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_unknown_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_unknown_vulnerabilities := get_patched_vulnerabilities(input, "Unknown")
  not count(rpms_with_unknown_vulnerabilities) == 0

  name := "clair_unknown_vulnerabilities"
  vulns_num := count_vulnerabilities(rpms_with_unknown_vulnerabilities)
  msg := "Found packages with unknown vulnerabilities. Consider updating to a newer version of those packages, they may no longer be affected by the reported CVEs."
  description := generate_description(rpms_with_unknown_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

warn_unpatched_unknown_vulnerabilities[{"msg": msg, "vulnerabilities_number": vulns_num, "details":{"name": name, "description": description, "url": url}}] {
  rpms_with_unpatched_unknown_vulnerabilities := get_unpatched_vulnerabilities(input, "Unknown")
  not count(rpms_with_unpatched_unknown_vulnerabilities) == 0

  name := "clair_unpatched_unknown_vulnerabilities"
  vulns_num := count_vulnerabilities(rpms_with_unpatched_unknown_vulnerabilities)
  msg := "Found packages with unpatched unknown vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := generate_description(rpms_with_unpatched_unknown_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}
