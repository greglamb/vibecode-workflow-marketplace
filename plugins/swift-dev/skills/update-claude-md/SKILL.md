---
name: update-claude-md
description: |
  Update swift-dev-managed sections in an existing CLAUDE.md in place.
  Replaces content between `<!-- swift-dev:managed:NAME -->` markers with
  the latest canonical snippets shipped by the plugin. Leaves unmanaged
  content untouched. Appends missing sections with markers so they become
  managed going forward.
  Use when the swift-dev plugin has shipped new CLAUDE.md sections and
  you want an existing project to pick them up without re-running init.
  Trigger with "update CLAUDE.md", "patch claude.md from swift-dev", or
  /swift-dev:update-claude-md.
allowed-tools: Read, Write, Edit, Bash
---

# Update swift-dev-managed sections in CLAUDE.md

Patches `CLAUDE.md` at the project root with the latest canonical content for plugin-managed sections. Safe to re-run — idempotent.

## Managed sections

Each section is identified by marker comments:

```
<!-- swift-dev:managed:NAME -->
…content…
<!-- /swift-dev:managed:NAME -->
```

Canonical content lives in `${CLAUDE_PLUGIN_ROOT}/snippets/claude-md/NAME.md`.

Current managed section names:
- `suggest-skills`
- `consult-skills`

## Steps

1. **Verify `CLAUDE.md` exists at the project root.** If not, tell the user to run `/swift-dev:init` first and stop.

2. **Read the current `CLAUDE.md`.** Keep the original content in mind so you can preserve everything outside managed sections.

3. **For each managed section name** (`suggest-skills`, `consult-skills`):

   a. Read the canonical snippet: `${CLAUDE_PLUGIN_ROOT}/snippets/claude-md/<NAME>.md`.

   b. Search `CLAUDE.md` for the marker pair `<!-- swift-dev:managed:<NAME> -->` and `<!-- /swift-dev:managed:<NAME> -->`.

   c. **If both markers are found:** replace everything between them with the snippet contents (preserve one blank line above and below the content, inside the markers). Use Edit with a regex-free exact match: read the current block, then do a literal replace.

   d. **If the markers are missing:** append the section at the end of `CLAUDE.md` (before any `@./docs/ARCHITECTURE.md` include, if present) wrapped in fresh markers:

   ```
   <!-- swift-dev:managed:<NAME> -->
   {snippet contents}
   <!-- /swift-dev:managed:<NAME> -->
   ```

   e. **If only one marker is found (orphan):** stop and report the corruption — do not guess. Ask the user to fix by hand or delete the orphan marker.

4. **Verify the result parses cleanly.** Re-read `CLAUDE.md`, confirm every managed section has a balanced open/close marker pair.

5. **Report** what changed:
   - Sections updated in place (marker pair existed, content differed)
   - Sections added (marker pair missing, now appended)
   - Sections unchanged (content already matched canonical)
   - Any orphan markers detected

## Constraints

- **Never touch content outside managed markers.** User customizations — build commands, coding standards, git conventions, custom sections — are sacred.
- **Never delete managed sections.** If a section is removed from the canonical snippet list in a future plugin version, leave the existing block alone and tell the user it's now unmanaged.
- **Preserve file ordering.** Don't reorder the user's sections. Only append (for missing sections) or replace-in-place (for existing ones).
- **Do not overwrite the `@./docs/ARCHITECTURE.md` include.** If present, keep it as the last line.
