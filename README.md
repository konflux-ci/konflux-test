# HACBS-TEST
This is HACBS-test team repository.
Purpose of this repo is to store resources, currently for tekton tasks and pipelines.


## Policy Unit Testing

Running command `opa test <path> [path [...]]` executes unit testing for policy, `path` points to the policy folder and unit testing fixtures data folder.

Running policy unit testing with code coverage report `opa test <path> [path [...]] -c`

Running policy unit testing and exit with non-zero status if coverage is less than threshold % `policy test <path> [path [...]] --threshold float`

In this repository, we run `opa test policies unittests unittests/test_data -c > /tmp/policy_unittest_result.json` to get unit testing code coverage and then analyze.


## Contact

### team HACBS: https://coreos.slack.com/archives/C034UFMUSV6
### forum HACBS: https://coreos.slack.com/archives/C030SGP2VB9
