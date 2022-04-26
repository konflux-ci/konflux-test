package required_checks

import data.rpm_manifest as rpm_manifest

test_violation_image_unsigned_rpms {
    result := violation_image_unsigned_rpms with input as rpm_manifest
    result[_].details.name == "image_unsigned_rpms"
    result[_].msg == "All RPMs found on the image must be signed. Found following unsigned rpms(nvra): perl-File-Path-2.09-2.el7.noarch"
}
