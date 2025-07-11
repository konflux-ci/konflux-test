# unittests/test_cosign/cosign-verify_test.rego
package cosign_checks

import data.cosign_verify_success as verify_success
import data.cosign_verify_unsigned as verify_unsigned  
import data.cosign_verify_invalid_cert as verify_invalid_cert
import data.cosign_verify_policy_violation as verify_policy_violation

# Test successful signature verification
test_cosign_verify_success {
    verify_success.status == "success"
    verify_success.verification.verified == true
    count(verify_success.verification.signatures) > 0
    verify_success.verification.issuer == "https://token.actions.githubusercontent.com"
}

# Test verification of unsigned image
test_cosign_verify_unsigned_image {
    verify_unsigned.status == "error"
    verify_unsigned.error_type == "unsigned"
    contains(verify_unsigned.error, "no matching signatures")
}

# Test certificate validation failure
test_cosign_verify_invalid_certificate {
    verify_invalid_cert.status == "error"
    verify_invalid_cert.error_type == "certificate"
    contains(verify_invalid_cert.error, "certificate verification failed")
}

# Test policy violation during verification
test_cosign_verify_policy_violation {
    verify_policy_violation.status == "error"
    verify_policy_violation.error_type == "policy"
    contains(verify_policy_violation.error, "policy verification failed")
}

# Test signature structure validation
test_cosign_signature_structure {
    signature := verify_success.verification.signatures[0]
    signature.keyid != ""
    signature.sig != ""
    signature.cert != ""
}

# Test verification metadata presence
test_cosign_verification_metadata {
    verify_success.verification.issuer != ""
    verify_success.verification.subject != ""
    startswith(verify_success.verification.subject, "https://github.com/")
}