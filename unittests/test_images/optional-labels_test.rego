package optional_checks

import data.bad_image as image

test_violation_maintainer_required {
    result := violation_maintainer_required with input as image
    result[_].details.name == "maintainer_label_required"
    result[_].msg == "The 'maintainer' label should be defined"
}

test_violation_summary_required {
    result := violation_summary_required with input as image
    result[_].details.name == "summary_label_required"
    result[_].msg == "The 'summary' label should be defined"
}
