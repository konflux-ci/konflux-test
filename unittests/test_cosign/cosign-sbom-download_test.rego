# unittests/test_cosign/cosign-sbom-download_test.rego
package cosign_checks

import data.cosign_sbom_success as success_data
import data.cosign_sbom_failure as failure_data

test_cosign_sbom_download_success {
    success_data.status == "success"
    success_data.sbom.spdxVersion == "SPDX-2.3"
}

test_cosign_sbom_download_auth_failure {
    failure_data.status == "error"
    failure_data.error_type == "authorization"
    contains(failure_data.error, "UNAUTHORIZED")
}