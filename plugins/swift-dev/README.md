# swift-dev

A Claude Code plugin for Swift/Apple development. Bundles skills, a subagent, and hooks into a single install, then scaffolds deterministic project-level rules on init.

## Quick start

### 1. Install the plugin (once, globally)

From the [`claude-gcode-tools`](https://github.com/greglamb/claude-gcode-tools) marketplace:

```bash
claude plugin marketplace add greglamb/claude-gcode-tools
claude plugin install swift-dev@claude-gcode-tools
```

### 2. Install Axiom (recommended, once, globally)

Axiom provides 175+ Apple development skills and autonomous agents:

```bash
claude plugin marketplace add CharlesWiltgen/Axiom
claude plugin install axiom@axiom-marketplace
```

If you skip this step, `/swift-dev:init` will detect that Axiom is missing and tell you how to install it.

### 3. Initialize a project (once per project)

Open Claude Code in a Swift project directory and run:

```
/swift-dev:init
```

If you forget this step, the session-start hook detects the uninitialized project and prompts you to run init.

Init detects your project structure and does three things:

- **Installs external skills** if missing — Paul Hudson's four Pro skills (SwiftUI, SwiftData, Concurrency, Testing), the Swift Architecture skill, and the Writing for Interfaces skill. If XcodeBuildMCP CLI is detected, installs its CLI skill too.
- **Scaffolds `.claude/rules/`** with four path-scoped rule files (SwiftUI, SwiftData, concurrency, testing) populated with guardrails that activate deterministically based on which files Claude touches
- **Generates project files** — a starter `CLAUDE.md` (~40 lines, populated from detected project context, with build commands matching your available tooling and a skill priority chain for conflict resolution) and `docs/ARCHITECTURE.md` (module layout, platforms, dependencies)

Init never overwrites existing files. If `CLAUDE.md` already exists, it shows what it would have written and suggests merging.

## Usage workflow

### What happens every session

When you start Claude Code in a Swift project, the plugin activates automatically:

1. **Session start hook** fires — injects your project name, git branch, Swift version, Xcode version, and which build tooling to use (xcodebuildmcp if available, native xcodebuild otherwise). If the project hasn't been initialized (no `.claude/rules/`), it prompts you to run `/swift-dev:init`.

2. **CLAUDE.md loads** (if initialized) — your project's build commands, coding standards, skill priority chain, and workflow are in context. The `@./docs/ARCHITECTURE.md` include gives Claude your module layout and data flow.

3. **Rules load on demand** — as Claude reads or edits files, matching `.claude/rules/` files activate. Edit a `*View.swift`? SwiftUI rules are in context. Edit a `*Tests.swift`? Testing rules load. Edit any `.swift` file? Concurrency rules apply. This is deterministic — path globs, not probabilistic skill matching.

4. **Hooks enforce safety on every edit** — when Claude writes or edits a file, two hooks fire in sequence:
   - **Pre-edit**: blocks writes to `.env`, `Secrets.swift`, `Credentials.swift`, `.p12`, `.mobileprovision`, and other sensitive files
   - **Post-edit**: if SwiftLint is installed and the file is `.swift`, runs SwiftLint and feeds any warnings back as context — Claude sees them and self-corrects without you intervening

All hooks detect whether the current directory is a Swift project. In non-Swift projects, they do nothing.

### Building a feature

A typical development flow using the plugin:

1. **Describe what you want** — Claude writes code with guidance from Axiom (175+ skills loaded on demand) and Hudson Pro skills (surgical LLM mistake correction for SwiftUI, SwiftData, concurrency, and testing)

2. **Build** — Claude runs `xcodebuild` (or `xcodebuildmcp build-sim` if installed) to compile. Errors are parsed from the output, fixed, and rebuilt.

3. **Test** — Claude runs the test suite. Failures get fixed.

4. **Verify UI** (if applicable) — Claude screenshots the simulator. If XcodeBuildMCP is installed, it can also inspect the accessibility tree via `describe-ui`.

5. **Review** — the `swift-reviewer` subagent examines `git diff` in a separate context against a Swift-specific checklist.

6. **Commit** — conventional commits (`feat:`, `fix:`, etc.)

You can do this conversationally, or use the slash commands to invoke specific workflows directly.

### Slash commands

These are the plugin's skills, available via the `/` menu:

| Command | When to use it | Auto-invokes? |
|---------|---------------|---------------|
| `/swift-dev:init` | First time opening a Swift project with this plugin | Yes — triggers on "set up for swift", "initialize project" |
| `/swift-dev:build-fix` | Build is broken, want autonomous fix loop | No — invoke explicitly |
| `/swift-dev:verify-ui` | Made UI changes, want visual + accessibility verification | No — invoke explicitly |
| `/swift-dev:health-check` | Pre-release or pre-PR full project audit | No — invoke explicitly |
| `/swift-dev:release` | Setting up macOS app signing, notarization, Homebrew cask, or release workflows | Yes — triggers on "ship macOS app", "notarize", "homebrew cask" |
| `/swift-dev:update-claude-md` | Plugin shipped new managed sections and you want existing projects to pick them up | No — invoke explicitly |

Code review is owned by `superpowers:requesting-code-review`; it can spawn the `swift-reviewer` subagent (shipped by this plugin) for Swift-specific checks.

Skills marked "No" for auto-invocation use `disable-model-invocation: true` — Claude won't run them unless you explicitly ask.

#### `/swift-dev:build-fix`

Runs an autonomous loop: build → read structured errors → fix source → rebuild. Repeats until the build is green, then runs tests. Reports what was broken and what it fixed. Does not ask for confirmation between iterations.

#### `/swift-dev:verify-ui`

Builds and launches the app in the simulator, takes a screenshot, and reports what's visible, whether it matches the task, and any accessibility issues. If XcodeBuildMCP is installed, also reads the accessibility tree via `describe-ui` for deeper inspection. If the build fails, it redirects to `build-fix` first.

#### `/swift-dev:health-check`

Comprehensive audit across all layers:
- **Build**: clean build (warnings), full test suite (pass/fail counts)
- **Axiom audits** (if installed): concurrency, memory, full health check
- **Code quality**: greps for deprecated APIs (`foregroundColor`, `NavigationView`), unsafe patterns (`@unchecked Sendable`, `@Attribute(.unique)`), and anti-patterns (`.onAppear { Task {`)

Reports issues grouped by severity (Critical / Warning / Info) with recommended fixes.

#### `swift-reviewer` subagent

Read-only Swift code reviewer shipped as an agent (not a slash command). Reviews against a prioritized checklist: correctness, concurrency safety, SwiftData rules, memory management, API deprecations, testability, and accessibility. Invoke it via `superpowers:requesting-code-review` (which owns the review *workflow*), or directly with the Agent tool. Returns structured findings by severity.

#### `/swift-dev:release`

House playbook for shipping a Developer-ID-signed, notarized macOS SwiftUI app via GitHub Actions and a Homebrew cask in the same repo. Covers the two-workflow CI/release layout, signing + notarization + stapling, signed DMG creation, pinned cask SHAs, CI-driven cask bumps, required GitHub secrets, Info.plist requirements, and common failure modes with fixes. Use when setting up release automation, authoring a Homebrew cask, or diagnosing notarization issues.

#### `/swift-dev:update-claude-md`

Idempotent patcher for existing `CLAUDE.md` files. When the plugin ships new managed sections (e.g. added "skills to consult during brainstorming"), run this in each existing project to pull the updates without re-running init. Finds `<!-- swift-dev:managed:NAME -->` markers and replaces content between them with the latest canonical snippet from `${CLAUDE_PLUGIN_ROOT}/snippets/claude-md/NAME.md`. Appends missing sections at the end. Never touches unmanaged content (build commands, coding standards, custom sections).

## What's in the plugin

```
swift-dev/
├── .claude-plugin/
│   └── plugin.json                  # Plugin manifest
├── skills/
│   ├── init/SKILL.md                # Project scaffolding + dependency install
│   ├── build-fix/SKILL.md           # Autonomous build-fix loop
│   ├── verify-ui/SKILL.md           # Screenshot + accessibility verification
│   ├── health-check/SKILL.md        # Full project audit
│   ├── release/SKILL.md             # macOS signing, notarization, Homebrew cask
│   └── update-claude-md/SKILL.md    # Patches managed sections in existing CLAUDE.md
├── snippets/
│   └── claude-md/                   # Canonical content for managed CLAUDE.md sections
│       ├── suggest-skills.md
│       └── consult-skills.md
├── agents/
│   └── swift-reviewer.md            # Read-only code reviewer (separate context)
├── hooks/
│   └── hooks.json                   # SessionStart, PreToolUse, PostToolUse
├── scripts/
│   ├── session-start.sh             # Injects project/branch/toolchain context
│   ├── pre-edit-protect-secrets.sh  # Blocks writes to sensitive files
│   ├── post-edit-swiftlint.sh       # Runs SwiftLint, feeds warnings as context
│   └── setup-dependencies.sh        # Installs XcodeBuildMCP, Hudson Pro, etc.
├── settings.json                    # Pre-approved permissions for Swift tooling
└── README.md
```

## What init scaffolds into your project

`/swift-dev:init` creates these files in your project directory:

```
your-project/
├── CLAUDE.md                    # Build commands, standards, workflow (~40 lines)
├── .claude/
│   └── rules/
│       ├── swiftui.md           # Loaded for *View.swift, *Screen.swift, Views/**, UI/**
│       ├── swiftdata.md         # Loaded for *Model.swift, *Schema.swift, Models/**
│       ├── concurrency.md       # Loaded for all *.swift
│       └── testing.md           # Loaded for *Tests.swift, *Test.swift, Tests/**
└── docs/
    └── ARCHITECTURE.md          # @-included by CLAUDE.md
```

Rules use path globs for **deterministic** activation. This is more reliable than skill auto-invocation for guardrails like "all SwiftData relationships must be optional" — if Claude touches a Model file, that rule is in context, guaranteed.

The `CLAUDE.md` is populated from your actual project: detected app name, platforms, architecture pattern, persistence framework, and dependencies. It includes a skill priority chain that resolves conflicts between rules, Hudson Pro, and Axiom. It stays under 50 lines — concise enough that every instruction gets followed.

## Architecture: three layers

This plugin composes with two external tool categories, plus an optional execution enhancer:

| Layer | What | Tool | Required? |
|-------|------|------|-----------|
| **Broad knowledge** | 175+ skills covering all Apple frameworks, 38 autonomous agents | [Axiom](https://github.com/CharlesWiltgen/Axiom) plugin | Recommended |
| **Deep knowledge** | Surgical LLM mistake correction for SwiftUI, SwiftData, Concurrency, Testing; 8-pattern architecture framework; UX copy review | [Hudson Pro skills](https://github.com/twostraws/Swift-Agent-Skills), [Architecture](https://github.com/efremidze/swift-architecture-skill), [UX Writing](https://github.com/andrewgleave/skills) | Installed by init |
| **Execution** | Structured JSON build output, UI automation, accessibility tree, LLDB debugging | [XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP) CLI + skill | Optional |

The plugin itself is the **glue layer**: workflows that orchestrate all three, hooks that enforce safety, and project scaffolding that configures deterministic rules. Hudson Pro skills and other external skills are installed by `/swift-dev:init`. Axiom requires manual plugin installation (see Quick Start).

### XcodeBuildMCP (optional, CLI mode)

All skills work with native `xcodebuild` and `xcrun simctl` — XcodeBuildMCP is not required. When present, skills automatically prefer it for structured JSON build output (less token waste), UI automation (tap, swipe, gesture), accessibility tree inspection (`describe-ui`), and LLDB debugging.

Install if you want these capabilities:

```bash
brew tap getsentry/xcodebuildmcp && brew install xcodebuildmcp
```

If installed before or during init, the scaffolded `CLAUDE.md` will include `xcodebuildmcp` commands. If installed later, update the build commands in your `CLAUDE.md`.

## Handling skill conflicts

Layers of guidance (rules, Superpowers, swift-dev, Hudson Pro, Axiom) will occasionally disagree — typically on style preferences, process ordering, or which iOS version's APIs to target, not on hard correctness issues. Claude Code has no built-in priority system for content conflicts across plugins.

The scaffolded `CLAUDE.md` includes an explicit priority chain:

1. **`CLAUDE.md` and `.claude/rules/`** — project-specific, always wins
2. **[Superpowers](https://github.com/obra/superpowers) skills** — workflow/process (brainstorming, plans, TDD, code review, debugging, worktrees, subagent-driven dev). Wins anywhere swift-dev overlaps on *process*.
3. **swift-dev skills** — Swift-specific workflows (init, build-fix, verify-ui, health-check, release) and the `swift-reviewer` subagent invoked through `superpowers:requesting-code-review`. TDD workflow is owned by Superpowers; Swift Testing syntax is enforced via `.claude/rules/testing.md`.
4. **Hudson Pro skills** — targeted LLM mistake corrections
5. **Axiom skills** — broad framework coverage

### Superpowers ↔ swift-dev overlap map

| Concern | Owner | swift-dev adds |
|---|---|---|
| TDD / RED-GREEN-REFACTOR | `superpowers:test-driven-development` | Swift Testing syntax (`@Test`, `#expect`) enforced via `.claude/rules/testing.md` (no swift-dev command) |
| Code review workflow | `superpowers:requesting-code-review`, `receiving-code-review` | `swift-reviewer` subagent (Swift-specific checklist) — invoked by superpowers, not a separate command |
| Debugging | `superpowers:systematic-debugging` | Xcode structured-error build loop in `/swift-dev:build-fix` |
| Planning, brainstorming, worktrees, subagent-driven dev, verification-before-completion, finishing a branch | Superpowers (no swift-dev equivalent) | — |
| Project scaffolding, simulator screenshot + a11y verification, full project health audit, macOS signing/notarization/Homebrew cask | swift-dev (no Superpowers equivalent) | — |

Rule of thumb: if it's a **process** question (how to plan, how to iterate, how to review, how to debug, when to cut a branch), defer to Superpowers. If it's a **Swift/Xcode/Apple-platform** question (which API, which build command, which lint rule, how to notarize), defer to swift-dev/Hudson Pro/Axiom in that order.

Because `CLAUDE.md` loads every session and Claude attends more to later context, this priority declaration is effective. If a rule says "use NavigationStack" and Axiom suggests a NavigationSplitView pattern for your use case, Claude follows the rule. If you want Axiom's recommendation for a specific case, override it in `CLAUDE.md` or the relevant rule file.

For deployment target conflicts (Axiom targets iOS 26+, your project may target iOS 17), the priority section includes a fallback: prefer the approach matching the project's minimum deployment target.

## Customizing

After init, the scaffolded files are yours to edit:

- **`CLAUDE.md`** — adjust build commands, add project-specific standards, change architecture pattern
- **`.claude/rules/`** — add new rule files with path globs for your frameworks (e.g., a `networking.md` scoped to `**/Network/**`), or edit existing rules to match your team's conventions
- **`docs/ARCHITECTURE.md`** — keep this updated as your project evolves; Claude reads it every session via the `@` include
- **`CLAUDE.local.md`** — create for personal overrides (gitignored by init); use for preferences that shouldn't be shared with the team

### Shorter command aliases

Plugin skills are always namespaced (`/swift-dev:build-fix`). If you want shorter aliases like `/build-fix`, create project-level command files in `.claude/commands/` — these aren't namespaced. For example, `.claude/commands/build-fix.md`:

```markdown
Run /swift-dev:build-fix
```

This gives you both `/build-fix` and `/swift-dev:build-fix` pointing to the same workflow.

## Requirements

- macOS with Xcode 16+
- [Claude Code](https://code.claude.com) CLI
- Node.js 18+ (for `npx skills` installs)
- [Homebrew](https://brew.sh) (optional — only needed to install XcodeBuildMCP)
- [SwiftLint](https://github.com/realm/SwiftLint) (optional — post-edit hook skips gracefully if not installed)

## License

MIT
