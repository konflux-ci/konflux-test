package main

deny[msg] {
  unsigned_rpms := {rpm.nvra | rpm := input.rpms[_]; not rpm.gpg}
  not count(unsigned_rpms) == 0

  msg = sprintf("All RPMs must be signed! Found following unsigned rpms(nvra): %s", [concat(", ", unsigned_rpms)])
}
