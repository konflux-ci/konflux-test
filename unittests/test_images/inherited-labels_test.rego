package optional_checks

import data.good_image as image
import data.good_image as base_image

test_violation_summary_label_inherited {
    result := violation_summary_label_inherited with input as image with data.Labels as base_image.Labels
    result[_].details.name == "summary_label_inherited"
    result[_].msg == "The 'summary' label should not be inherited from the base image"
}

test_violation_description_label_inherited {
    result := violation_description_label_inherited with input as image with data.Labels as base_image.Labels
    result[_].details.name == "description_label_inherited"
    result[_].msg == "The 'description' label should not be inherited from the base image"
}

test_violation_io_k8s_description_label_inherited {
    result := violation_io_k8s_description_label_inherited with input as image with data.Labels as base_image.Labels
    result[_].details.name == "io_k8s_description_label_inherited"
    result[_].msg == "The 'io.k8s.description' label should not be inherited from the base image"
}

test_violation_io_k8s_display_name_label_inherited {
    result := violation_io_k8s_display_name_label_inherited with input as image with data.Labels as base_image.Labels
    result[_].details.name == "io_k8s_display_name_label_inherited"
    result[_].msg == "The 'io.k8s.display-name' label should not be inherited from the base image"
}

test_violation_io_openshift_tags_label_inherited {
    result := violation_io_openshift_tags_label_inherited with input as image with data.Labels as base_image.Labels
    result[_].details.name == "io_openshift_tags_label_inherited"
    result[_].msg == "The 'io.openshift.tags' label should not be inherited from the base image"
}
