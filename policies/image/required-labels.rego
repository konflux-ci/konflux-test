package required_checks

violation_name_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["name"]

  name := "name_label_required"
  msg := "The required 'name' label is missing!"
  description := "Name of the Image or Container."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_com_redhat_component_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["com.redhat.component"]

  name := "com_redhat_component_label_required!"
  msg := "The required 'com.redhat.component' label is missing"
  description := "The Bugzilla component name where bugs against this container should be reported by users."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_version_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["version"]

  name := "version_label_required"
  msg := "The required 'version' label is missing!"
  description := "Version of the image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_description_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["description"]

  name := "description_label_required"
  msg := "The required 'description' label is missing!"
  description := "Detailed description of the image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_io_k8s_description_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["io.k8s.description"]

  name := "io_k8s_description_label_required"
  msg := "The required 'io.k8s.description' label is missing!"
  description := "Description of the container displayed in Kubernetes."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_vcs_ref_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["vcs-ref"]

  name := "vcs_ref_label_required"
  msg := "The required 'vcs-ref' label is missing!"
  description := "A 'reference' within the version control repository; e.g. a git commit, or a subversion branch."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_vcs_type_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["vcs-type"]

  name := "vcs_type_label_required"
  msg := "The required 'vcs-type' label is missing!"
  description := "The type of version control used by the container source. Generally one of git, hg, svn, bzr, cvs"
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_architecture_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["architecture"]

  name := "architecture_label_required"
  msg := "The required 'architecture' label is missing!"
  description := "Architecture the software in the image should target."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_vendor_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["vendor"]

  name := "vendor_label_required"
  msg := "The required 'vendor' label is missing!"
  description := "Name of the vendor."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_release_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["release"]

  name := "release_label_required"
  msg := "The required 'release' label is missing!"
  description := "Release Number for this version."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_url_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["url"]

  name := "url_label_required"
  msg := "The required 'url' label is missing!"
  description := "A URL where the user can find more information about the image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_build_date_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["build-date"]

  name := "build_date_label_required"
  msg := "The required 'build-date' label is missing!"
  description := "Date/Time image was built as RFC 3339 date-time."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_distribution_scope_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["distribution-scope"]

  name := "distribution_scope_label_required"
  msg := "The required 'distribution-scope' label is missing!"
  description := "Scope of intended distribution of the image. (private/authoritative-source-only/restricted/public)."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}
