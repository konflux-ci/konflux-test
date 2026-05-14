# Konflux-test
This is the konflux-test repository for building the image of the same name.

## Purpose

The Konflux Test image consolidates multiple CLI tools into a single container
image, simplifying Tekton task creation and reducing the maintenance overhead of
managing multiple tool-specific images.

The image contains bash utility functions which are meant to support
task execution with testable utilities. Furthermore, it also contains [Conftest](https://www.conftest.dev/) 
policies which are used in Konflux testing tasks

The image is primarily geared towards usage in Tekton tasks belonging to the following repositories:

* [konflux-test-tasks](https://github.com/konflux-ci/konflux-test-tasks)
* [konflux-sast-tasks](https://github.com/konflux-ci/konflux-sast-tasks)
* [konflux-operator-tasks](https://github.com/konflux-ci/konflux-operator-tasks)

### Building the Image

Locally:

```sh
podman build -t konflux-test .
```

For production: we use [Konflux CI](https://konflux-ci.dev/). See the pipelines in `.tekton/`.
The latest versions of the image can be found at [quay.io/konflux-ci/konflux-test](https://quay.io/repository/konflux-ci/konflux-test).

## Adding New Tools

### Criteria

Tools must meet the following requirements for inclusion:

- Must be a standalone CLI tool
  - Language runtimes are also acceptable (e.g. Python)
- Must be installable [hermetically](https://konflux-ci.dev/docs/building/hermetic-builds/)
- Must follow a versioning scheme (preferably semantic versioning)
- Should have release notes or a changelog

## Conftest policies

This image contains Conftest [OPA policies](https://www.openpolicyagent.org/) written in Rego language.
They are meant to be used as part of Konflux Tekton tasks when parsing testing outputs.

### Prerequisites for running policies locally

Install the following list of packages to run the policies locally.

1. [Conftest](https://www.conftest.dev/install/)
2. [jq](https://snapcraft.io/jq)
3. [Skopeo](https://github.com/containers/skopeo/blob/main/install.md)

### Policy Unit Testing

In addition to [prerequisites](https://github.com/konflux-ci/konflux-test#prerequisites) install the packages below to run unit testing.

1. [OPA](https://www.openpolicyagent.org/docs/latest/#running-opa)

Running command `opa test <path> [path [...]]` executes unit testing for policy, `path` points to the policy folder and unit testing fixtures data folder.

Running policy unit testing with code coverage report `opa test <path> [path [...]] -c`

Running policy unit testing and exit with non-zero status if coverage is less than threshold % `policy test <path> [path [...]] --threshold float`

In this repository, we run `opa test policies unittests unittests/test_data -c > /tmp/policy_unittest_result.json` to get unit testing code coverage and then analyze.

### Policy Integration Testing

In addition to [prerequisites](https://github.com/konflux-ci/konflux-test#prerequisites) install the packages below to run integration testing.

1. [BATS](https://github.com/bats-core/bats-core/releases)

Run Integration tests locally by export the policies directory path to `policies` folder as shown below.

```
export POLICY_PATH=policies
sh test/entrypoint.sh
```

## Releasing

### Versioning

When making a new release, bump the version according to the first matching rule:

- Bump the **major** number if this version:
  - Removes a tool
  - Updates the major version of any tool
  - Makes a different breaking change
- Bump the **minor** number if this version:
  - Adds a new tool
  - Updates the minor version of any tool
  - Adds a different new feature
- Otherwise, bump the **patch** number
