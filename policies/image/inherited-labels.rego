package optional_checks

import data as base_image

violation_summary_label_inherited[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["summary"] == base_image.Labels["summary"]

  name := "summary_label_inherited"
  msg := "The 'summary' label should not be inherited from the base image"
  description := "If the label is inherited from the base image but not specified in the Dockerfile, it will contain an incorrect value for the built image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#anchor_b2ba2cc8-61f4-ea11-80ed-000d3a020feb"
}

violation_description_label_inherited[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["description"] == base_image.Labels["description"]

  name := "description_label_inherited"
  msg := "The 'description' label should not be inherited from the base image"
  description := "If the label is inherited from the base image but not specified in the Dockerfile, it will contain an incorrect value for the built image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#anchor_b2ba2cc8-61f4-ea11-80ed-000d3a020feb"
}

violation_io_k8s_description_label_inherited[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["io.k8s.description"] == base_image.Labels["io.k8s.description"]

  name := "io_k8s_description_label_inherited"
  msg := "The 'io.k8s.description' label should not be inherited from the base image"
  description := "If the label is inherited from the base image but not specified in the Dockerfile, it will contain an incorrect value for the built image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#anchor_b2ba2cc8-61f4-ea11-80ed-000d3a020feb"
}

violation_io_k8s_display_name_label_inherited[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["io.k8s.display-name"] == base_image.Labels["io.k8s.display-name"]

  name := "io_k8s_display_name_label_inherited"
  msg := "The 'io.k8s.display-name' label should not be inherited from the base image"
  description := "If the label is inherited from the base image but not specified in the Dockerfile, it will contain an incorrect value for the built image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#anchor_b2ba2cc8-61f4-ea11-80ed-000d3a020feb"
}

violation_io_openshift_tags_label_inherited[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.Labels["io.openshift.tags"] == base_image.Labels["io.openshift.tags"]

  name := "io_openshift_tags_label_inherited"
  msg := "The 'io.openshift.tags' label should not be inherited from the base image"
  description := "If the label is inherited from the base image but not specified in the Dockerfile, it will contain an incorrect value for the built image."
  url := "https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/guide_to_layered_image_build_service_osbs#anchor_b2ba2cc8-61f4-ea11-80ed-000d3a020feb"
}