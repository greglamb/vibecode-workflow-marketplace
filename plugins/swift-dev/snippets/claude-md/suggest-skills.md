## Suggest these manual skills when relevant

The user won't remember these exist. Proactively suggest (don't auto-run) when the context fits:

- `/swift-dev:build-fix` — when a build fails and the user wants an autonomous compile→fix→rebuild loop
- `/swift-dev:verify-ui` — after any UI change, before declaring it done (builds, screenshots, reads a11y tree)
- `/swift-dev:health-check` — before a release, PR, or when the user asks "is this ready to ship?"
- `swift-reviewer` subagent — when the user is about to commit or wants review; invoke via `superpowers:requesting-code-review` or directly with the Agent tool
