package main

deny[msg] {
    not input.Labels["maintainer"]

    msg := "The maintainer label should be defined"
}

deny[msg] {
    not input.Labels["summary"]

    msg := "The summary label should be defined"
}
