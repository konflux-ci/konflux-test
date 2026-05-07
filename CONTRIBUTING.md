# Contributing

- [How to Report Issues](#how-to-report-issues)
- [How to Submit Pull Requests](#how-to-submit-pull-requests)
    - [Development Workflow](#development-workflow)
    - [Pull Request Guidelines](#pull-request-guidelines)
    - [Security basics](#security-basics)
- [Review Process](#review-process)


Contributions of all kinds are welcome. In particular pull requests are appreciated. The authors and maintainers will endeavor to help walk you through any issues in the pull request discussion, so please feel free to open a pull request even if you are new to such things.

> [!NOTE]
> This repository is used in [Konflux](https://konflux-ci.dev).
> Therefore, everybody should follow its [Code of Conduct](https://github.com/konflux-ci/community/blob/main/CODE_OF_CONDUCT.md).

## How to Report Issues

- We encourage early communication for all types of contributions.
- Before filing an issue, make sure to check if it is not reported already.
- If the contribution is non-trivial (straightforward bugfixes, typos, etc.), please open an issue to discuss your plans and get guidance from maintainers.

## How to Submit Pull Requests

### Development Workflow

1. **Fork and Clone**: Fork this repository and clone your fork
2. **Create Feature Branch**: Create a new topic branch based on `main`
3. **Make Changes**: Implement your changes. Consult [README.md](README.md) for the structure and development details.
4. **Commit Changes**: See [commit guidelines](#pull-request-guidelines)

### Pull Request Guidelines

**Commit Requirements:**

- Write clear, descriptive commit titles. Should fit under 50 characters
- Write meaningful commit descriptions with each line having less than 72 characters
- Split your contribution into several commits if applicable, each should represent a logical chunk
- Add line `Assisted-by: <name-of-ai-tool>` if you used an AI tool for your contribution
- Sign-off your commits in order to certify that you adhere to [Developer Certificate of Origin](https://developercertificate.org)

**Pull Request Content:**

- **Title**: Clear, descriptive title. Should fit under 72 characters.
- **Description**: Explain the overall changes and their purpose, this should be a cover letter for your commits.
- **Testing**: Describe how the changes were tested
- **Links**: Reference related issues or upstream stories.

**Remember:**

- Konflux is a community project and proper descriptions cannot be replaced by referencing a publicly inaccessible link to Jira or any other private resource.
- Reviewers, other contributors and future generations might not have the same context as you have at the moment of PR submission.

### Security basics

- Never commit secrets or keys to the repository
- Never expose or log sensitive information

## Review Process

**Requirements for Approval:**

- All CI checks pass
- Code review approval from maintainers

**Review Criteria:**

- The contribution follows established patterns and conventions
- Changes are tested and documented
- Security best practices are followed

For any questions or help with contributing, please open an issue or reach out to the maintainers.
