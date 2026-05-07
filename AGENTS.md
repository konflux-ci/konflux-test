## AGENTS.md

This is the Konflux-test repository for building the image of the same name. The main purpose of this image is to store resources used in Konflux CI Tekton tasks and pipelines such as tools, `conftest` policies and bash utility functions.

## Technology Stack

- **Language**: Rego, bash
- **Pipeline engine**: Tekton PipelineRuns
- **Testing**: Tekton integration pipelines and GitHub actions
- **Build**: Dockerfile, Tekton build pipelines

## Repository Structure

```
policies/              # OPA/conftest policies written in Rego that are used in Konflux Tekton tasks for validating formatted outputs
test/                  # Bash utility functions which are used in Tekton steps along with associated test files
parsers/               # JQ parsers for transforming JSON outputs
unittests/             # OPA Rego unit tests for policies contained in the policies/ directory
unittests_bash/        # Bats-powered unit tests for bash utility functions contained in the test/ directory
.tekton/               # Tekton build PipelineRuns which create Tekton bundle images
integration-tests/     # Tekton integration test PipelineRuns for validating the image's functionality
rpms.*                 # Contain packages that are built hermetically with their corresponding location
hack/                  # Various scripts that are used during the CI runs
```

## Architecture

### Conftest Policies
The most important part of this repository is the collection of OPA Rego policies in the `policies/` directory which are meant to be executed by the `conftest` utility. These policies are meant to validate structured outputs from different checks which are executed as part of the Tekton tasks mainly located in the [konflux-test-tasks](https://github.com/konflux-ci/konflux-test-tasks/),  [konflux-operator-tasks](https://github.com/konflux-ci/konflux-operator-tasks) and [konflux-sast-tasks](https://github.com/konflux-ci/konflux-sast-tasks) repositories.

### Bash utility functions
The Bash utility functions in the `test/` directory are meant to be used in the Tekton task steps in order to support the Konflux CI Tekton task logic. These functions are meant to reduce the size and complexity of the scripts embedded within the Task steps, while being more directly testable by the Bats unit tests in the `unittests_bash/` directory.

### Image-hosted utilities
The `konflux-test` image also contains additional utilities (binaries, scripts, etc.) which are required by the Konflux CI Tekton tasks. See the `Dockerfile` for more details on them.

## Development Guidelines

- See `CONTRIBUTING.md` for overall guidelines for making contributions to this repository.
- **Git**: conventional commits with Jira ticket as scope — `type(issue-id): description` (e.g. `feat(STONEINTG-1519): create PR group snapshots from ComponentGroups`)
    - The `main` branch is read only, never push there directly, a new feature branch must be created instead
    - Pull requests are used to propose changes to the `main` branch
- Don't change whitespaces or newlines in the existing unrelated code and never add whitespaces or tabs to empty lines
- Don't remove unrelated code and don't change files when/where modifications are not needed
- Don't add trailing newlines at the end of file, last newline character is at the end of code
- Make sure that the OPA Rego policies are covered by unit tests in the `unittests` directory
- Make sure that the bash functions are covered by unit tests in the `unittests_bash` directory
- Make sure that the Dockerfile is well-formatted and does not include unnecessary layers
