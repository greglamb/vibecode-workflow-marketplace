---
description: Setup the development environment
---
Before continuing, do the following exactly once:

1. Check if the project root is a git repository (look for `.git/`). If not, run `git init`.
2. Create the .worktrees directory in the project root and add it to gitignore
3. Create the _gitignored directory in the project root and add both `_gitignored` and `_reference` to gitignore (the `_reference` entry is kept for backwards compatibility with existing projects)
4. Create the TODO.md file in the project root
5. Create the CHANGELOG.md file in the project root
6. Set up goodvibes-workflow using the goodvibes-workflow skill
7. Make sure the following skills are available - if they are not then notify the user how to obtain them:
  - superpowers
    - Obtain it by running:
     - /plugin marketplace add obra/superpowers-marketplace
     - /plugin install superpowers@superpowers-marketplace
  - episodic-memory
    - Obtain it by running:
      - /plugin marketplace add obra/superpowers-marketplace
      - /plugin install episodic-memory@superpowers-marketplace
  - project-standards
    - Obtain it by running an example such as this:
      - /vibecreatestandards Apply best practices for developing this application such as solid, yagni, kiss, dry, and tdd
8. Set up gitleaks pre-commit hook for secret detection:
  a. Check if `pre-commit` is installed by running `pre-commit --version`.
     - If not installed, try in this order:
       1. `brew install pre-commit`
       2. If brew is unavailable or fails: `uv tool install pre-commit`
       3. If uv is unavailable: `pipx install pre-commit`
     - Verify installation succeeded before continuing.
  b. Check if `.pre-commit-config.yaml` already exists in the repo root.
     - If it exists, append the gitleaks repo entry to the existing `repos` list (do not modify existing hooks).
     - If it doesn't exist, create it.
  c. Add/merge this configuration into `.pre-commit-config.yaml`:
     ```yaml
     repos:
       - repo: https://github.com/gitleaks/gitleaks
         rev: v8.21.2
         hooks:
           - id: gitleaks
     ```
  d. Check if `.gitleaks.toml` exists in the repo root.
     - If not, create one with an empty allowlist:
       ```toml
       title = "Gitleaks config"

       [allowlist]
         description = "Allowlisted patterns"
         paths = []
       ```
  e. Run `pre-commit install` to register the hook in `.git/hooks/`.
  f. Run `pre-commit run gitleaks --all-files` to verify it works and catch any existing secrets.
  g. If secrets are found, report them but do NOT auto-fix or remove them. List the findings and stop.
  h. Add `.pre-commit-config.yaml` and `.gitleaks.toml` to a commit with message:
     `chore: add gitleaks pre-commit hook for secret detection`
  - Constraints:
    - Do not install gitleaks globally — let pre-commit manage it.
    - Do not modify any existing hooks in `.pre-commit-config.yaml`.
    - Do not remove or alter `.gitignore`.
