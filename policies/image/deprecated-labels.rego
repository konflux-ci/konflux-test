package required_checks

violation_install_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["INSTALL"]

  name := "install_label_deprecated"
  msg := "The INSTALL label is deprecated!"
  description := "The 'INSTALL' label is deprecated, replace with 'install'"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_architecture_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["Architecture"]

  name := "architecture_label_deprecated"
  msg := "The Architecture label is deprecated!"
  description := "The 'Architecture' label is deprecated, replace with 'architecture'"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_name_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["Name"]

  name := "name_label_deprecated"
  msg := "The Name label is deprecated!"
  description := "The 'Name' label is deprecated, replace with 'name'"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_release_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["Release"]

  name := "release_label_deprecated"
  msg := "The Release label is deprecated!"
  description := "The 'Release' label is deprecated, replace with 'release'"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_uninstall_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["UNINSTALL"]

  name := "uninstall_label_deprecated"
  msg := "The UNINSTALL label is deprecated!"
  description := "The 'UNINSTALL' label is deprecated, replace with 'uninstall'"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_version_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["Version"]

  name := "version_label_deprecated"
  msg := "The Version label is deprecated!"
  description := "The 'Version' label is deprecated, replace with 'version'"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_bzcomponent_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["BZComponent"]

  name := "bzcomponent_label_deprecated"
  msg := "The BZComponent label is deprecated!"
  description := "The BZComponent label is deprecated, replace with 'com.redhat.component'"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_run_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["RUN"]

  name := "run_label_deprecated"
  msg := "The RUN label is deprecated!"
  description := "The 'RUN' label is deprecated, replace with 'run'"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}
