package fbc_checks

violation_fbc_dc_required[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  not input.Labels["operators.operatorframework.io.index.configs.v1"]

  name := "operators_operatorframework_io_index_configs_v1_label_required"
  msg := "The 'operators.operatorframework.io.index.configs.v1' label should be defined for FBC image"
  description := "Should set DC-specific label `operators.operatorframework.io.index.configs.v1` for the location of the DC root directory for FBC image."
  url := "https://docs.openshift.com/container-platform/4.9/operators/admin/olm-managing-custom-catalogs.html#olm-creating-fb-catalog-image_olm-managing-custom-catalogs"
}
