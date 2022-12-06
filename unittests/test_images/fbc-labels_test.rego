package fbc_checks

import data.good_image as image

test_violation_fbc_dc_required {
    result := violation_fbc_dc_required with input as image
    result[_].details.name == "operators_operatorframework_io_index_configs_v1_label_required"
    result[_].msg == "The 'operators.operatorframework.io.index.configs.v1' label should be defined for FBC image"
}
