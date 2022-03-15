package main

deny[msg] {
  input.Labels["INSTALL"]

  msg := "The INSTALL label is deprecated, replace with 'install'"
}

deny[msg] {
  input.Labels["Architecture"]

  msg := "The Architecture label is deprecated, replace with 'architecture'"
}

deny[msg] {
  input.Labels["Name"]

  msg := "The Name label is deprecated, replace with 'name'"
}

deny[msg] {
  input.Labels["Release"]

  msg := "The Release label is deprecated, replace with 'release'"
}

deny[msg] {
  input.Labels["UNINSTALL"]

  msg := "The UNINSTALL label is deprecated, replace with 'uninstall'"
}

deny[msg] {
  input.Labels["Version"]

  msg := "The Version label is deprecated, replace with 'version'"
}

deny[msg] {
  input.Labels["BZComponent"]

  msg := "The BZComponent label is deprecated, replace with 'com.redhat.component'"
}

deny[msg] {
  input.Labels["RUN"]

  msg := "The RUN label is deprecated, replace with 'run'"
}
