# Cosign Testing Guide

## Overview
This document describes the testing approach for cosign functionality in the konflux-test project.

## Test Categories

### Unit Tests
- Located in `unittests/test_cosign/`
- Test cosign command parsing and response handling
- Mock cosign operations for controlled testing

### Integration Tests  
- Located in `unittests_bash/test_utils.bats`
- Test actual cosign binary interactions
- Include authentication scenarios

### E2E Tests
- Located in `test/conftest.sh`
- Test cosign in the context of deprecated-image-check workflow
- Verify proper error handling for authorization issues

## Running Tests

```bash
# Run all cosign tests
bats unittests_bash/test_utils.bats -f cosign

# Run unit tests with OPA
opa test unittests/test_cosign/ unittests/test_data/
```

## Key Test Scenarios

1. **Version Check**: Verify cosign binary is present and functional
2. **SBOM Download**: Test successful SBOM retrieval from public images
3. **Authorization Handling**: Test proper error handling for private images
4. **Error Recovery**: Test graceful handling of network/service errors
5. **Deprecated Image Check Integration**: Test cosign in the context of the actual task workflow