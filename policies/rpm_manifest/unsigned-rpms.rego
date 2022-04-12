package required_checks

violation_image_unsigned_rpms[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  unsigned_rpms := {rpm.nvra | rpm := input.rpms[_]; not rpm.gpg}
  not count(unsigned_rpms) == 0

  name := "image_unsigned_rpms"
  msg = sprintf("All RPMs found on the image must be signed. Found following unsigned rpms(nvra): %s", [concat(", ", unsigned_rpms)])
  description := "Providing packages signed with the secure Red Hat signing server indicates that the package was subject to all appropriate policies and procedures."
  url := "https://docs.engineering.redhat.com/display/PRODSEC/PSP4.0+-+Offerings+Built+Securely"
}
