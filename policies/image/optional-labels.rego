package optional_checks

violation_maintainer_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["maintainer"]

  name := "maintainer_label_required"
  msg := "The 'maintainer' label should be defined"
  description := "The name and email of the maintainer (usually the submitter). Should contain `@redhat.com` or `Red Hat`."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}

violation_summary_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["summary"]

  name := "summary_label_required"
  msg := "The 'summary' label should be defined"
  description := "A short description of the image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#jive_content_id_Labels"
}
