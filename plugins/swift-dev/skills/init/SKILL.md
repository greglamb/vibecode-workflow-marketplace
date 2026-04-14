---
name: init
description: |
  Initialize a Swift project for Claude Code. Scaffolds .claude/rules/ with
  path-scoped SwiftUI, SwiftData, concurrency, and testing rules, a starter
  CLAUDE.md, and docs/ARCHITECTURE.md. Also installs external dependencies
  (XcodeBuildMCP, Axiom, Hudson Pro skills) if missing.
  Use when starting a new Swift/iOS project or onboarding an existing one.
  Trigger with "initialize project", "set up for swift", or /swift-dev:init.
allowed-tools: Read, Write, Bash
---

# Initialize Swift project for Claude Code

Run these steps in order. Do not skip any step. Do not ask for confirmation between steps.

## Step 1: Check and install external dependencies

Run `${CLAUDE_PLUGIN_ROOT}/scripts/setup-dependencies.sh` to install XcodeBuildMCP CLI, Axiom plugin, and Hudson Pro skills if they're missing. Report what was installed vs already present.

After the script completes, check if Axiom is installed by looking for any skills with "axiom" in the namespace. If Axiom is NOT installed, display this prominently — not buried in other output:

**⚠️ Axiom is not installed.** Add its marketplace and install the plugin:
```bash
claude plugin marketplace add CharlesWiltgen/Axiom
claude plugin install axiom@axiom-marketplace
```
After installing, run `/reload-plugins` if you ran the commands from inside Claude Code, or just restart the session.

Axiom provides 175+ Apple development skills and autonomous agents. The plugin works without it, but you lose broad framework coverage.

## Step 2: Detect project context

Inspect the project root to determine:
- Project name (from .xcodeproj, .xcworkspace, Package.swift, or directory name)
- Platforms targeted (scan for platform declarations in Package.swift or project settings)
- Min deployment target
- Architecture pattern in use (look for ViewModels/, Stores/, Reducers/, etc.)
- SPM dependencies (from Package.swift or Package.resolved)
- Whether SwiftData, Core Data, or neither is used
- Whether tests exist and what framework (Swift Testing vs XCTest)

## Step 3: Create .claude/rules/

Create the directory `.claude/rules/` if it doesn't exist, then write these four files.

**`.claude/rules/swiftui.md`**:
```markdown
---
paths:
  - "**/*View.swift"
  - "**/*Screen.swift"
  - "**/Views/**"
  - "**/UI/**"
  - "**/Components/**"
---

# SwiftUI rules

- Use `foregroundStyle()` not `foregroundColor()` — the latter is deprecated
- Use `containerRelativeFrame` over `GeometryReader` when possible
- NavigationStack with path-based routing, not deprecated NavigationView
- Use `.task {}` for async work, not `.onAppear` with Task {}
- Prefer `@Observable` macro (iOS 17+) over ObservableObject/Published
- Extract reusable views into separate files when they exceed ~50 lines
- Add `.accessibilityLabel()` to all interactive elements and icons
- Use `@Environment(\.dismiss)` not `@Environment(\.presentationMode)`
```

**`.claude/rules/swiftdata.md`**:
```markdown
---
paths:
  - "**/Models/**"
  - "**/*Model.swift"
  - "**/*Schema.swift"
  - "**/Persistence/**"
---

# SwiftData rules

- All relationships MUST be optional — SwiftData crashes on non-optional relationships
- Never use `@Attribute(.unique)` — it causes silent data loss on conflicts
- Use explicit `#Index` macros for query performance
- ModelContainer configuration belongs in the App struct, not in views
- Use `@Query` in views, `modelContext.fetch()` in non-view code
- Always wrap batch operations in `modelContext.transaction {}`
- Test migration paths — create a versioned schema enum
```

**`.claude/rules/concurrency.md`**:
```markdown
---
paths:
  - "**/*.swift"
---

# Swift concurrency rules

- Never assume state is unchanged after an `await` — actor reentrancy invalidates assumptions
- Use `@MainActor` on view models and UI-touching code, not manual DispatchQueue.main
- Prefer structured concurrency (async let, TaskGroup) over unstructured Task {}
- All Sendable conformances must be verified — don't just slap `@unchecked Sendable` on things
- Use `actor` for mutable shared state, not classes with locks
- Cancel tasks explicitly when views disappear — use `.task {}` modifier which auto-cancels
- When bridging completion handlers, use `withCheckedContinuation` (not unsafe variant) unless performance-critical
```

**`.claude/rules/testing.md`**:
```markdown
---
paths:
  - "**/*Tests.swift"
  - "**/*Test.swift"
  - "**/Tests/**"
---

# Testing rules

- Use Swift Testing framework (`@Test`, `#expect`) not XCTest for new tests
- Parameterized tests with `@Test(arguments:)` for multiple input scenarios
- Use traits: `@Test(.tags(.ui))`, `@Test(.timeLimit(.minutes(1)))`
- `#expect(throws:)` for error testing, not do/catch blocks
- Name tests descriptively: `@Test("User login fails with invalid credentials")`
- Test file mirrors source: `Models/User.swift` → `Tests/UserTests.swift`
- Mock protocols, not concrete types — inject dependencies via init
```

If the project doesn't use SwiftData, skip `swiftdata.md` and note that you skipped it.

## Step 4: Create CLAUDE.md

Write a `CLAUDE.md` at the project root using the detected project context. Keep it under 50 lines.

**Managed sections.** Some sections are marked with `<!-- swift-dev:managed:NAME -->` … `<!-- /swift-dev:managed:NAME -->` markers. For these, read the referenced snippet file at `${CLAUDE_PLUGIN_ROOT}/snippets/claude-md/NAME.md` and insert its contents **verbatim** between the markers. These markers let `/swift-dev:update-claude-md` patch the sections in place when the plugin ships new versions — do not remove the markers.

First, check if `xcodebuildmcp` is available (`which xcodebuildmcp`). Use the appropriate template:

**If xcodebuildmcp IS available:**

```markdown
# {ProjectName} — Claude Code configuration

{One-line description of what the project is, platform, and stack.}

## Build & test

Use `xcodebuildmcp` CLI for builds, tests, and simulator interaction. Discover commands with `xcodebuildmcp --help` and `xcodebuildmcp tools`.

- Build & run: `xcodebuildmcp build-and-run`
- Test: `xcodebuildmcp test-sim`
- Screenshot: `xcodebuildmcp screenshot`
- Accessibility tree: `xcodebuildmcp describe-ui`

## Coding standards

- Swift 6 strict concurrency
- {Architecture pattern} architecture
- {Persistence framework} for persistence
- Minimum 75% unit test coverage; all tests must pass before committing

## Skill priority

When skills or plugins give conflicting guidance, follow this order:
1. This file and `.claude/rules/` — project-specific, always wins
2. Superpowers skills — workflow/process (brainstorming, plans, TDD, code review, debugging, worktrees). Wins over swift-dev on any *process* overlap.
3. swift-dev skills — Swift-specific workflows (build-fix, verify-ui, health-check, release) and Swift-specific checklists layered onto Superpowers workflows
4. Hudson Pro skills — targeted LLM mistake corrections
5. Axiom skills — broad framework coverage

Overlap rule of thumb: **process** questions (how to plan/iterate/review/debug) → Superpowers; **Swift/Xcode/Apple-platform** questions (which API, build command, lint rule, notarization) → swift-dev → Hudson Pro → Axiom.

If still ambiguous, prefer the approach that targets this project's minimum deployment target.

## Workflow

1. For process (planning, TDD, review, debugging, worktrees) defer to Superpowers; for Swift/Xcode/Apple specifics check swift-dev, then Hudson Pro, then Axiom
2. Write code following skill guidance
3. Build — read errors, fix, rebuild
4. Run tests — fix failures
5. Verify UI changes with screenshot and describe-ui

## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`

<!-- swift-dev:managed:suggest-skills -->
{CONTENTS OF ${CLAUDE_PLUGIN_ROOT}/snippets/claude-md/suggest-skills.md, INSERTED VERBATIM}
<!-- /swift-dev:managed:suggest-skills -->

<!-- swift-dev:managed:consult-skills -->
{CONTENTS OF ${CLAUDE_PLUGIN_ROOT}/snippets/claude-md/consult-skills.md, INSERTED VERBATIM}
<!-- /swift-dev:managed:consult-skills -->

@./docs/ARCHITECTURE.md
```

**If xcodebuildmcp is NOT available:**

```markdown
# {ProjectName} — Claude Code configuration

{One-line description of what the project is, platform, and stack.}

## Build & test

- Build: `xcodebuild build -scheme {Scheme} -destination 'platform=iOS Simulator,name=iPhone 16'`
- Test: `xcodebuild test -scheme {Scheme} -destination 'platform=iOS Simulator,name=iPhone 16'`
- For SPM-only: `swift build` and `swift test`
- Screenshot: `xcrun simctl io booted screenshot /tmp/screenshot.png`

## Coding standards

- Swift 6 strict concurrency
- {Architecture pattern} architecture
- {Persistence framework} for persistence
- Minimum 75% unit test coverage; all tests must pass before committing

## Skill priority

When skills or plugins give conflicting guidance, follow this order:
1. This file and `.claude/rules/` — project-specific, always wins
2. Superpowers skills — workflow/process (brainstorming, plans, TDD, code review, debugging, worktrees). Wins over swift-dev on any *process* overlap.
3. swift-dev skills — Swift-specific workflows (build-fix, verify-ui, health-check, release) and Swift-specific checklists layered onto Superpowers workflows
4. Hudson Pro skills — targeted LLM mistake corrections
5. Axiom skills — broad framework coverage

Overlap rule of thumb: **process** questions (how to plan/iterate/review/debug) → Superpowers; **Swift/Xcode/Apple-platform** questions (which API, build command, lint rule, notarization) → swift-dev → Hudson Pro → Axiom.

If still ambiguous, prefer the approach that targets this project's minimum deployment target.

## Workflow

1. For process (planning, TDD, review, debugging, worktrees) defer to Superpowers; for Swift/Xcode/Apple specifics check swift-dev, then Hudson Pro, then Axiom
2. Write code following skill guidance
3. Build — read errors, fix, rebuild
4. Run tests — fix failures
5. Verify UI changes with simulator screenshots

## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`

<!-- swift-dev:managed:suggest-skills -->
{CONTENTS OF ${CLAUDE_PLUGIN_ROOT}/snippets/claude-md/suggest-skills.md, INSERTED VERBATIM}
<!-- /swift-dev:managed:suggest-skills -->

<!-- swift-dev:managed:consult-skills -->
{CONTENTS OF ${CLAUDE_PLUGIN_ROOT}/snippets/claude-md/consult-skills.md, INSERTED VERBATIM}
<!-- /swift-dev:managed:consult-skills -->

@./docs/ARCHITECTURE.md
```

If `CLAUDE.md` already exists, do NOT overwrite it. Instead, show the user what you would have written and suggest they merge relevant parts.

## Step 5: Create docs/ARCHITECTURE.md

Create `docs/` directory if needed, then write `docs/ARCHITECTURE.md` populated with detected project context (app name, platforms, module layout from actual directory structure, dependencies from Package.swift, data flow pattern).

If `docs/ARCHITECTURE.md` already exists, skip this step.

## Step 6: Create .gitignore entries

Append `CLAUDE.local.md` to `.gitignore` if it's not already there.

## Step 7: Report

Summarize what was created, what was skipped (and why), and what external tools were installed. List the slash commands now available:
- `/swift-dev:build-fix`
- `/swift-dev:verify-ui`
- `/swift-dev:health-check`
- `/swift-dev:release`

For TDD workflow, use `superpowers:test-driven-development` — the Swift Testing specifics (`@Test`, `#expect`) are enforced via `.claude/rules/testing.md`. For code review, use `superpowers:requesting-code-review` which can spawn the `swift-reviewer` subagent shipped by this plugin.
