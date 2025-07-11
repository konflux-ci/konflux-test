# unittests/test_cosign/cosign-auth_test.rego
package cosign_checks

import data.cosign_auth_public_success as public_success
import data.cosign_auth_private_unauthorized as private_unauthorized
import data.cosign_auth_invalid_credentials as invalid_creds
import data.cosign_auth_valid_credentials as valid_creds
import data.cosign_auth_token_expired as token_expired
import data.cosign_auth_registry_unavailable as registry_unavailable

# Test successful access to public registry (no auth required)
test_cosign_auth_public_registry_success {
    public_success.auth_required == false
    public_success.access_granted == true
    public_success.status == "success"
}

# Test unauthorized access to private registry
test_cosign_auth_private_unauthorized {
    private_unauthorized.auth_required == true
    private_unauthorized.credentials_provided == false
    private_unauthorized.status == "error"
    private_unauthorized.error_type == "unauthorized"
    contains(private_unauthorized.error, "UNAUTHORIZED")
}

# Test invalid credentials scenario
test_cosign_auth_invalid_credentials {
    invalid_creds.auth_required == true
    invalid_creds.credentials_provided == true
    invalid_creds.credentials_valid == false
    invalid_creds.status == "error"
    invalid_creds.error_type == "invalid_credentials"
    contains(invalid_creds.error, "authentication required")
}

# Test valid credentials scenario
test_cosign_auth_valid_credentials {
    valid_creds.auth_required == true
    valid_creds.credentials_provided == true
    valid_creds.credentials_valid == true
    valid_creds.access_granted == true
    valid_creds.status == "success"
}

# Test token expiration scenario
test_cosign_auth_token_expired {
    token_expired.auth_required == true
    token_expired.credentials_provided == true
    token_expired.token_expired == true
    token_expired.status == "error"
    token_expired.error_type == "token_expired"
    contains(token_expired.error, "token expired")
}

# Test registry network unavailability
test_cosign_auth_registry_unavailable {
    registry_unavailable.auth_required == true
    registry_unavailable.registry_accessible == false
    registry_unavailable.status == "error"
    registry_unavailable.error_type == "network"
    contains(registry_unavailable.error, "no such host")
}

# Test registry type classification
test_cosign_registry_classification {
    public_success.registry == "quay.io"
    private_unauthorized.registry == "quay.io" 
    invalid_creds.registry == "registry.redhat.io"
    token_expired.registry == "ghcr.io"
}

# Test error message patterns for different auth failures
test_cosign_auth_error_patterns {
    # Unauthorized access pattern
    contains(private_unauthorized.error, "UNAUTHORIZED: access to the requested resource is not authorized")
    
    # Authentication required pattern  
    contains(invalid_creds.error, "UNAUTHORIZED: authentication required")
    
    # Token expired pattern
    contains(token_expired.error, "token expired")
}

# Test auth requirement detection
test_cosign_auth_requirement_detection {
    # Public registry should not require auth
    public_success.auth_required == false
    
    # Private registries should require auth
    private_unauthorized.auth_required == true
    invalid_creds.auth_required == true
    valid_creds.auth_required == true
    token_expired.auth_required == true
}

# Test credential validation logic
test_cosign_credential_validation {
    # No credentials provided case
    private_unauthorized.credentials_provided == false
    
    # Invalid credentials case
    invalid_creds.credentials_provided == true
    invalid_creds.credentials_valid == false
    
    # Valid credentials case
    valid_creds.credentials_provided == true
    valid_creds.credentials_valid == true
}