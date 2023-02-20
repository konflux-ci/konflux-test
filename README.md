# HACBS-TEST
This is HACBS-test team repository.
Purpose of this repo is to store resources, currently for tekton tasks and pipelines.

## Prerequisites

Install the following list of packages to run the policies locally.

  1. [Conftest](https://www.conftest.dev/install/)
  2. [jq](https://snapcraft.io/jq)
  3. [Skopeo](https://github.com/containers/skopeo/blob/main/install.md) 

## Policy Unit Testing

In addition to [prerequisites](https://github.com/redhat-appstudio/hacbs-test#prerequisites) install the packages below to run unit testing.

  1. [OPA](https://www.openpolicyagent.org/docs/latest/#running-opa)

Running command `opa test <path> [path [...]]` executes unit testing for policy, `path` points to the policy folder and unit testing fixtures data folder.

Running policy unit testing with code coverage report `opa test <path> [path [...]] -c`

Running policy unit testing and exit with non-zero status if coverage is less than threshold % `policy test <path> [path [...]] --threshold float`

In this repository, we run `opa test policies unittests unittests/test_data -c > /tmp/policy_unittest_result.json` to get unit testing code coverage and then analyze.

## Policy Integration Testing

In addition to [prerequisites](https://github.com/redhat-appstudio/hacbs-test#prerequisites) install the packages below to run integration testing.

  1. [BATS](https://github.com/bats-core/bats-core/releases)

Run Integration tests locally by export the policies directory path to `policies` folder as shown below.

`export POLICY_PATH=policies`

`sh test/entrypoint.sh`

## Contact

### team HACBS: https://coreos.slack.com/archives/C034UFMUSV6
### forum HACBS: https://coreos.slack.com/archives/C030SGP2VB9

