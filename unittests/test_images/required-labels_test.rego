package required_checks

import data.bad_image as image

test_violation_name_required {
    result := violation_name_required with input as image
    result[_].details.name == "name_label_required"
    result[_].msg == "The required 'name' label is missing!"
}

test_violation_com_redhat_component_required {
    result := violation_com_redhat_component_required with input as image
    result[_].details.name == "com_redhat_component_label_required!"
    result[_].msg == "The required 'com.redhat.component' label is missing"
}

test_violation_version_required {
    result := violation_version_required with input as image
    result[_].details.name == "version_label_required"
    result[_].msg == "The required 'version' label is missing!"
}

test_violation_description_required {
    result := violation_description_required with input as image
    result[_].details.name == "description_label_required"
    result[_].msg == "The required 'description' label is missing!"
}

test_violation_io_k8s_description_required {
    result := violation_io_k8s_description_required with input as image
    result[_].details.name == "io_k8s_description_label_required"
    result[_].msg == "The required 'io.k8s.description' label is missing!"
}

test_violation_vcs_ref_required {
    result := violation_vcs_ref_required with input as image
    result[_].details.name == "vcs_ref_label_required"
    result[_].msg == "The required 'vcs-ref' label is missing!"
}

test_violation_vcs_type_required {
    result := violation_vcs_type_required with input as image
    result[_].details.name == "vcs_type_label_required"
    result[_].msg == "The required 'vcs-type' label is missing!"
}

test_violation_architecture_required {
    result := violation_architecture_required with input as image
    result[_].details.name == "architecture_label_required"
    result[_].msg == "The required 'architecture' label is missing!"
}

test_violation_vendor_required {
    result := violation_vendor_required with input as image
    result[_].details.name == "vendor_label_required"
    result[_].msg == "The required 'vendor' label is missing!"
}

test_violation_release_required {
    result := violation_release_required with input as image
    result[_].details.name == "release_label_required"
    result[_].msg == "The required 'release' label is missing!"
}

test_violation_url_required {
    result := violation_url_required with input as image
    result[_].details.name == "url_label_required"
    result[_].msg == "The required 'url' label is missing!"
}

test_violation_build_date_required {
    result := violation_build_date_required with input as image
    result[_].details.name == "build_date_label_required"
    result[_].msg == "The required 'build-date' label is missing!"
}

test_violation_distribution_scope_required {
    result := violation_distribution_scope_required with input as image
    result[_].details.name == "distribution_scope_label_required"
    result[_].msg == "The required 'distribution-scope' label is missing!"
}
