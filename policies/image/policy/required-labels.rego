package main

deny[msg] {
  not input.Labels.name

  msg := "The name label needs to be defined"
}

deny[msg] {
  not input.Labels["com.redhat.component"]

  msg := "The com.redhat.component label needs to be defined"
}

deny[msg] {
  not input.Labels.version

  msg := "The version label needs to be defined"
}

deny[msg] {
  not input.Labels.description

  msg := "The description label needs to be defined"
}

deny[msg] {
  not input.Labels["io.k8s.description"]

  msg := "The io.k8s.description_label label needs to be defined"
}

deny[msg] {
  not input.Labels["vcs-ref"]

  msg := "The vcs-ref label needs to be defined"
}

deny[msg] {
  not input.Labels["vcs-type"]

  msg := "the vcs-type label needs to be defined"
}

deny[msg] {
  not input.Labels.architecture

  msg := "the architecture label needs to be defined"
}

deny[msg] {
  not input.Labels["com.redhat.build-host"]

  msg := "the com.redhat.build-host label needs to be defined"
}

deny[msg] {
  not input.Labels.vendor

  msg := "the vendor label needs to be defined"
}

deny[msg] {
  not input.Labels.release

  msg := "the release label needs to be defined"
}

deny[msg] {
  not input.Labels.url

  msg := "the url label needs to be defined"
}

deny[msg] {
  not input.Labels["build-date"]

  msg := "the build-date label needs to be defined"
}

deny[msg] {
  not input.Labels["distribution-scope"]

  msg := "the distribution-scope label needs to be defined"
}

