# goodvibes-workflow

A project template for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that provides structured commands, skills, hooks, and documentation conventions out of the box.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- The following dependency plugins (see [Recommended Extras](../../README.md#recommended-extras) for details):
  - **superpowers** — planning, brainstorming, TDD, code review
  - **episodic-memory** — persistent context across sessions
  - **skill-creator** — skill authoring (used by `/vibecreatestandards`)

## Getting Started

1. **Install the plugin:**

   ```bash
   claude plugin marketplace add greglamb/claude-gcode-tools
   claude plugin install goodvibes-workflow@claude-gcode-tools
   ```

2. **Install dependency plugins:**

   ```bash
   claude plugin marketplace add obra/superpowers-marketplace
   claude plugin install superpowers@superpowers-marketplace
   claude plugin install episodic-memory@superpowers-marketplace
   claude plugin install skill-creator@claude-plugins-official
   ```

3. **Run setup** — Use `/vibesetup` to initialize your project environment (creates `.worktrees/`, `_gitignored/`, `TODO.md`, `CHANGELOG.md`, and configures `CLAUDE.md`).

4. **Define your standards** — Use `/vibecreatestandards` to generate a `project-standards` skill, or manually edit `.claude/skills/project-standards/SKILL.md` with your project's coding conventions, linting rules, and architectural guidelines. This skill is invoked before any code is written or modified. For help authoring skills, try using the [Anthropic Skill Creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) or the [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) tool.

5. **Add reference files** — Drop style guides, API specs, or other reference material into `.claude/skills/project-standards/references/`.

6. **Start Claude Code** from the project root:

   ```bash
   claude
   ```

7. **Use the commands** — Type `/vibecheck`, `/vibecommit`, `/vibetodo`, etc. in your Claude Code session.

## What's Included

### Custom Slash Commands

| Command                | Example                                                                                                                    | Description                                                                                                                                                                                                                                                             |
|------------------------|----------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/vibeplan`            | /vibeplan Phase 2 from TODO.md OR /vibeplan The implementation of REQUIREMENTS.md using a phased approach                  | Syncs episodic memory, loads superpowers, then plans using brainstorm + extension skills. Afterward it will ask if you want to start implementation or make changes to the plan. You will also have the option to perform the implementation as a Subagent-Driven task. |
| `/vibecheck`           | /vibecheck                                                                                                                 | Runs unit and integration tests, validates code against project standards                                                                                                                                                                                               |
| `/vibecommit`          | /vibecommit                                                                                                                | Diffs changes, generates a [Conventional Commits](https://www.conventionalcommits.org/) message with [Gitmoji](https://gitmoji.dev/), stages, and commits                                                                                                               |
| `/vibepush`            | /vibepush                                                                                                                  | Push changes to remote                                                                                                                                                                                                                                                  |
| `/vibenext`            | /vibenext                                                                                                                  | Asks Claude what it thinks the next logical step is (doesn't actually do it yet)                                                                                                                                                                                        |
| `/vibetodo`            | /vibetodo                                                                                                                  | Review the current `TODO.md` contents                                                                                                                                                                                                                                   |
| `/vibeclean`           | /vibeclean                                                                                                                 | Cleans up the current `TODO.md` contents                                                                                                                                                                                                                                |
| `/vibesetup`           | /vibesetup                                                                                                                 | Sets up the development environment: creates `.worktrees/`, `_gitignored/`, `TODO.md`, `CHANGELOG.md`, and verifies required plugins are available                                                                                                                      |
| `/vibecreatestandards` | /vibecreatestandards Apply best practices for developing this application such as solid, yagni, kiss, dry, and tdd         | Creates the `project-standards` skill based on your requirements using `skill-creator` from claude-plugins-official                                                                                                                                                     |
| `/vibebackup`          | /vibebackup TODO.md _gitignored/_archive/todo/                                                                             | Copies a file to a target directory with a Unix epoch timestamp in the filename                                                                                                                                                                                         |
| `/vibedebug`           | /vibedebug                                                                                                                 | Uses `superpowers:systematic-debugging` to review files in `_gitignored/debug`                                                                                                                                                                                          |

### Dependency Plugins

Three marketplace plugins are required:

- 🔌 **superpowers** — Extended planning, brainstorming, and verification capabilities
- 🔌 **episodic-memory** — Persistent context across Claude Code sessions
- 🔌 **skill-creator** — Skill authoring (used by `/vibecreatestandards`)

### Documentation Conventions

- **`CLAUDE.md`** — Project-level instructions Claude reads automatically. Enforces that all changes update `CHANGELOG.md` and `TODO.md`.
- **`CHANGELOG.md`** — Track all user-facing changes here.
- **`TODO.md`** — Track deferred work, known limitations, and planned features. The template enforces a "no silent deferrals" rule: anything out of scope must be logged.
- **`docs/plans/`** — Directory for longer-form planning documents.

## Customization

### Adding Commands

Create a new markdown file in `.claude/commands/`:

```markdown
---
name: my-command
description: What it does
---
Your prompt instructions here
```

### Adding Skills

Create a directory under `.claude/skills/` with a `SKILL.md` file and an optional `references/` folder for supporting docs. For help authoring skills, try using the [Anthropic Skill Creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) or the [Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers) tool.

### Restricting Tool Access

Commands can declare `allowed-tools` in their frontmatter to limit what Claude can do (see `vibecommit.md` for an example that restricts to git operations only).
