# Konflux-test AI Skills

Repository-specific AI skills for the konflux-test container image. These skills are tool-agnostic and can be used with any AI agent (Claude Code, Codex, Goose, etc.) via symlinks to the agent's skill directory.

## Available Skills

| Skill | Description |
|-------|-------------|
| [writing-rego-policies](writing-rego-policies/SKILL.md) | How to write OPA/conftest Rego policies: package naming, rule prefixes, violation objects, conftest namespaces, and unit tests |
| [writing-bash-functions](writing-bash-functions/SKILL.md) | How to add bash utility functions to test/utils.sh, naming conventions, BATS tests, mock patterns, and TEST_OUTPUT format |
| [running-tests-locally](running-tests-locally/SKILL.md) | How to run OPA unit tests, BATS tests, shellcheck, hadolint, conftest integration tests, and coverage reporting |
| [pr-definition-of-done](pr-definition-of-done/SKILL.md) | Pre-push checklist: conventional commits, Rego policy tests at 100% coverage, BATS tests, code quality checks |
| [ci-cd-quirks](ci-cd-quirks/SKILL.md) | Non-obvious CI/CD behavior: hermetic builds, Tekton pipelines, GitHub Actions checks, integration test structure |
| [adding-tools-to-image](adding-tools-to-image/SKILL.md) | How to add new tools/binaries to the container image: artifacts.lock.yaml, rpms.in.yaml, multi-arch support, hermetic builds |

## Setup for Claude Code

Skills are symlinked from `.claude/skills/` for automatic discovery:

```
.claude/skills/writing-rego-policies -> ../../skills/writing-rego-policies
.claude/skills/writing-bash-functions -> ../../skills/writing-bash-functions
...
```

## Setup for Other Agents

Create symlinks from your agent's skill directory to `skills/`:

```bash
# Example for Codex
ln -s ../../skills/writing-rego-policies .agents/skills/writing-rego-policies
```
