package required_checks

import data.bad_image as image

test_violation_install_deprecated {
    result := violation_install_deprecated with input as image
    result[_].details.name == "install_label_deprecated"
    result[_].msg == "The INSTALL label is deprecated!"
}

test_violation_architecture_deprecated {
    result := violation_architecture_deprecated with input as image
    result[_].details.name == "architecture_label_deprecated"
    result[_].msg == "The Architecture label is deprecated!"
}

test_violation_name_deprecated {
    result := violation_name_deprecated with input as image
    result[_].details.name == "name_label_deprecated"
    result[_].msg == "The Name label is deprecated!"
}

test_violation_release_deprecated {
    result := violation_release_deprecated with input as image
    result[_].details.name == "release_label_deprecated"
    result[_].msg == "The Release label is deprecated!"
}

test_violation_uninstall_deprecated {
    result := violation_uninstall_deprecated with input as image
    result[_].details.name == "uninstall_label_deprecated"
    result[_].msg == "The UNINSTALL label is deprecated!"
}

test_violation_version_deprecated {
    result := violation_version_deprecated with input as image
    result[_].details.name == "version_label_deprecated"
    result[_].msg == "The Version label is deprecated!"
}

test_violation_bzcomponent_deprecated {
    result := violation_bzcomponent_deprecated with input as image
    result[_].details.name == "bzcomponent_label_deprecated"
    result[_].msg == "The BZComponent label is deprecated!"
}

test_violation_run_deprecated {
    result := violation_run_deprecated with input as image
    result[_].details.name == "run_label_deprecated"
    result[_].msg == "The RUN label is deprecated!"
}
