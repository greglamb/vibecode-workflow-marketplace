# vibecode-workflow-marketplace

## Install

```bash
claude plugin marketplace add greglamb/vibecode-workflow-marketplace
claude plugin install vibecode-workflow@vibecode-workflow-marketplace
```

Optional extras:

```bash
claude plugin install vscode-api@vibecode-workflow-marketplace
claude plugin install fish-shell@vibecode-workflow-marketplace
```

## Plugin: vibecode-workflow

A project template for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that provides structured commands, skills, and documentation conventions out of the box.

### Getting Started

1. **Install Claude Code** if you haven't already:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **Install the plugin** from your project directory:
   ```bash
   claude plugin marketplace add greglamb/vibecode-workflow-marketplace
   claude plugin install vibecode-workflow@vibecode-workflow-marketplace
   ```

3. **Install dependency plugins** — The workflow uses two additional marketplace plugins:
   ```bash
   /plugin marketplace add obra/superpowers-marketplace
   /plugin install superpowers@superpowers-marketplace
   /plugin install episodic-memory@superpowers-marketplace
   /plugin install skill-creator@claude-plugins-official
   ```

4. **Run setup** — Use `/setthevibe` to initialize your project environment (creates `.worktrees/`, `_reference/`, `TODO.md`, `CHANGELOG.md`, and configures `CLAUDE.md`).

5. **Define your standards** — Use `/preparestandards` to generate a `project-standards` skill, or manually edit `.claude/skills/project-standards/SKILL.md` with your project's coding conventions, linting rules, and architectural guidelines. This skill is invoked before any code is written or modified. For help authoring skills, try using the [Anthropic Skill Creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) or the [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) tool.

6. **Add reference files** — Drop style guides, API specs, or other reference material into `.claude/skills/project-standards/references/`.

7. **Start Claude Code** from the project root:
   ```bash
   claude
   ```

8. **Use the commands** — Type `/check`, `/commit`, `/todo`, etc. in your Claude Code session.

### What's Included

#### Custom Slash Commands (`.claude/commands/`)

| Command             | Example                                                                                                         | Description                                                                                                                                                                                                                                                             |
|---------------------|-----------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/plotcaper`        | /plotcaper Phase 2 from TODO.md OR /plotcaper The implementation of REQUIREMENTS.md using a phased approach     | Syncs episodic memory, loads superpowers, then plans using brainstorm + extension skills. Afterward it will ask if you want to start implementation or make changes to the plan. You will also have the option to perform the implementation as a Subagent-Driven task. |
| `/check`            | /check                                                                                                          | Runs unit and integration tests, validates code against project standards                                                                                                                                                                                               |
| `/commit`           | /commit                                                                                                         | Diffs changes, generates a [Conventional Commits](https://www.conventionalcommits.org/) message with [Gitmoji](https://gitmoji.dev/), stages, and commits                                                                                                               |
| `/push`             | /push                                                                                                           | Push changes to remote                                                                                                                                                                                                                                                  |
| `/next`             | /next                                                                                                           | Asks Claude what it thinks the next logical step is (doesn't actually do it yet)                                                                                                                                                                                        |
| `/todo`             | /todo                                                                                                           | Review the current `TODO.md` contents                                                                                                                                                                                                                                   |
| `/clean`            | /clean                                                                                                          | Cleans up the current `TODO.md` contents                                                                                                                                                                                                                                |
| `/setthevibe`       | /setthevibe                                                                                                     | Sets up the development environment: creates `.worktrees/`, `_reference/`, `TODO.md`, `CHANGELOG.md`, and verifies required plugins are available                                                                                                                       |
| `/preparestandards` | /preparestandards Apply best practices for developing this application such as solid, yagni, kiss, dry, and tdd | Creates the `project-standards` skill based on your requirements using `skill-creator` from claude-plugins-official                                                                                                                                                     |
| `/backup`           | /backup TODO.md _reference/_archive/todo/                                                                       | Copies a file to a target directory with a Unix epoch timestamp in the filename                                                                                                                                                                                         |
| `/vibedebug`        | /vibedebug                                                                                                      | Uses `superpowers:systematic-debugging` to review files in `_reference/debug`                                                                                                                                                                                           |

#### Project Skills (`.claude/skills/`)

- **project-standards** — Define your coding standards, linting rules, and conventions here. Referenced by `CLAUDE.md` as a required skill before any code changes.

#### Plugins (`.claude/settings.json`)

Two marketplace plugins are enabled by default:

- **superpowers** — Extended planning, brainstorming, and verification capabilities
- **episodic-memory** — Persistent context across Claude Code sessions

#### Documentation Conventions

- **`CLAUDE.md`** — Project-level instructions Claude reads automatically. Enforces that all changes update `CHANGELOG.md` and `TODO.md`.
- **`CHANGELOG.md`** — Track all user-facing changes here.
- **`TODO.md`** — Track deferred work, known limitations, and planned features. The template enforces a "no silent deferrals" rule: anything out of scope must be logged.
- **`docs/plans/`** — Directory for longer-form planning documents.

### Customization

#### Adding Commands

Create a new markdown file in `.claude/commands/`:

```markdown
---
name: my-command
description: What it does
---
Your prompt instructions here
```

#### Adding Skills

Create a directory under `.claude/skills/` with a `SKILL.md` file and an optional `references/` folder for supporting docs. For help authoring skills, try using the [Anthropic Skill Creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) or the [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) tool.

#### Restricting Tool Access

Commands can declare `allowed-tools` in their frontmatter to limit what Claude can do (see `commit.md` for an example that restricts to git operations only).

## Plugin: vscode-api

VS Code Extension API documentation and guidance for building VS Code extensions. Covers commands, webviews, tree views, language features, activation events, contribution points, and the extension manifest.

## Plugin: fish-shell

Fish shell (version 4.0.2) documentation for writing fish scripts, configuring fish, understanding fish syntax, and migrating from bash. Includes command references for string manipulation, control flow, variables, functions, jobs, I/O, and more.

## Recommended Plugins

These plugins are not included in this marketplace but pair well with vibecode-workflow:

- **[skill-seekers](https://github.com/greglamb/skill-seekers-marketplace)** — Create AI skills from documentation, code repositories, and other sources. Requires [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) to be installed (`pipx install skill-seekers[mcp]` or `brew install skill-seekers`).
  ```bash
  claude plugin marketplace add greglamb/skill-seekers-marketplace
  claude plugin install skill-seekers@skill-seekers-marketplace
  ```

### Swift / Apple Development

- **[SwiftUI Agent Skill](https://github.com/twostraws/SwiftUI-Agent-Skill)** — Helps AI coding assistants write better SwiftUI code with guidance on API usage, design, performance, and accessibility.
- **[SwiftData Agent Skill](https://github.com/twostraws/SwiftData-Agent-Skill)** — Targets common LLM mistakes in SwiftData model definitions, queries, predicates, indexes, migrations, and iCloud sync.
- **[Swift Concurrency Agent Skill](https://github.com/twostraws/Swift-Concurrency-Agent-Skill)** — Targets common LLM mistakes in async/await, actors, Sendable, and structured concurrency patterns.
- **[Swift Testing Agent Skill](https://github.com/twostraws/Swift-Testing-Agent-Skill)** — Improves Swift test code targeting common LLM mistakes with `@Test`, `#expect`, parameterized testing, and traits.
- **[Swift API Design Guidelines](https://github.com/Erikote04/Swift-API-Design-Guidelines-Agent-Skill)** — Structured guidance on Swift API naming, argument labels, terminology, and conventions aligned with Apple's official guidelines.
- **[Swift Architecture Skill](https://github.com/efremidze/swift-architecture-skill)** — Routes to the right design pattern based on your feature's needs with scoped playbooks for Swift development.
- **[Swift Security Skill](https://github.com/ivan-magda/swift-security-skill)** — Reviews and implements secure credential storage, biometric authentication, and cryptography using Keychain Services and CryptoKit.
- **[SwiftUI Performance Audit](https://github.com/Dimillian/Skills/tree/main/swiftui-performance-audit)** — Identifies and resolves performance issues in SwiftUI applications through systematic auditing.
- **[iOS Simulator Skill](https://github.com/conorluddy/ios-simulator-skill)** — Automation toolkit enabling Claude Code to build, test, and interact with iOS apps using semantic navigation.
- **[Writing for Interfaces](https://github.com/andrewgleave/skills/tree/main/writing-for-interfaces)** — Reviews and evaluates UI copy for clarity, purpose, and consistency by establishing product voice and applying structured writing principles.

## License

MIT
