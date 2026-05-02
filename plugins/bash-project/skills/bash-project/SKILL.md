---
name: bash-project
description: Build and maintain multi-file Bash shell projects that run unchanged on macOS (default Bash 3.2.57) and modern Linux. Use this skill whenever the user is working on a shell script project, mentions Bash portability or macOS/Linux compatibility, asks to split a large monolithic shell script into modules, or wants conventions for shell project layout, sourcing/module loading, function namespacing, cross-platform helpers (sed, readlink, date, mktemp, stat), or testing with bats-core. Trigger eagerly any time the user is editing or creating files in a `bin/` or `lib/` directory of shell scripts, any time a `.sh` file is in scope, or any time you would otherwise be tempted to reach for Bash 4+ features such as associative arrays, mapfile, readarray, case-conversion expansions, coproc, or wait -n.
---

# Portable Bash Projects (Bash 3.2.57 baseline)

This skill is for writing shell projects that stay maintainable as they grow and run unchanged on macOS (default `/bin/bash` is 3.2.57 — Apple has frozen it there since the GPLv3 license change) and modern Linux. Every pattern in this skill is verified against Bash 3.2.57.

The skill optimizes for two things at once:

1. **Modularity.** Single-file shell scripts become unreadable around 300 lines. Use the project layout, sourcing pattern, and namespacing conventions below to split logic into modules without fighting the shell.
2. **Bash 3.2 portability.** Modern guides assume Bash 4+ or 5+. They will lead you astray. Treat every Bash 4+ feature as forbidden unless this skill or the user explicitly says otherwise.

## Hard constraint: Bash 3.2.57 only

You are writing for Bash 3.2.57 on macOS and modern Bash on Linux. Do **not** use any of these:

- Associative arrays (`declare -A`, `local -A`)
- `mapfile` / `readarray`
- Case-conversion expansions: `${var^^}`, `${var,,}`, `${var^}`, `${var,}`
- The `&>>` redirection (append stdout+stderr)
- `coproc`
- `wait -n`
- `BASHPID`
- `${parameter@operator}` transformations (`@Q`, `@E`, `@P`, `@A`, `@a`)
- `printf -v 'arr[i]' ...` writing into an array element (broken in 3.2)
- Brace expansion with variables: `{$a..$b}` does not expand — use `seq` or a `while` loop
- `${!prefix*}` / `${!prefix@}` — these *do* exist in 3.2 but behave inconsistently; prefer explicit lists

When you need any of these, see `references/bash3-gotchas.md` for the verified portable replacement.

You are also writing for **macOS userland** (BSD coreutils) as well as Linux (GNU coreutils). `sed -i`, `readlink -f`, `date -d`, `stat`, `mktemp`, `grep -P`, `find -printf`, and `xargs` differ between the two. Centralize these in `lib/platform.sh` (template provided in `assets/lib/platform.sh`).

## Project layout

Use this layout for any project past one file. Templates for every file marked `[T]` live in `assets/`:

```
myproject/
├── bin/                    # executable entry points (one per CLI command)
│   └── mytool          [T]
├── lib/                    # sourced modules — never executed directly
│   ├── _bootstrap.sh   [T] # module loader; underscore sorts it first
│   ├── log.sh          [T] # logging helpers (log::info, log::error, ...)
│   ├── platform.sh     [T] # macOS vs Linux abstractions
│   └── <feature>.sh        # one file per coherent module
├── test/                   # bats-core tests, one *.bats per module
│   └── log.bats        [T]
├── share/                  # static data, templates, fixtures
├── .editorconfig       [T]
├── .shellcheckrc       [T]
├── .shfmt              [T] # via Makefile flags
├── Makefile            [T]
└── README.md
```

Rules:

- Files in `bin/` are thin: `set -euo pipefail`, source the bootstrap, parse args, dispatch to a `lib/` function. Real logic lives in `lib/`.
- Files in `lib/` are *sourced*, never executed. They define functions and constants. They must not have side effects at source time except setting readonly constants.
- Every shell file has a `.sh` extension *except* the entry points in `bin/`, which have no extension (so `mytool` not `mytool.sh`). Users typing `mytool` shouldn't see the implementation language.

## Strict-mode preamble

**Every executable script** in `bin/` starts with this exact preamble:

```bash
#!/usr/bin/env bash
# Bash 3.2.57+ compatible. Do not use Bash 4+ features.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIB_DIR="${PROJECT_ROOT}/lib"

# shellcheck source=../lib/_bootstrap.sh
. "${LIB_DIR}/_bootstrap.sh"
```

Notes:

- `set -u` (the `u` in `-euo`) interacts badly with empty arrays in Bash 3.2. When expanding a possibly-empty array, write `"${arr[@]+"${arr[@]}"}"` (the canonical safe form) — not `"${arr[@]:-}"` which collapses to a single empty string.
- `IFS=$'\n\t'` is the Bash Strict Mode default. Drop the tab if you need to split on spaces in a specific scope; restore in a `local IFS=` inside the function rather than mutating globally.
- `${BASH_SOURCE[0]}` is reliable in 3.2; do **not** use `$0` for path resolution (it's wrong when sourced).
- The `cd ... && pwd` idiom is the portable way to get an absolute, symlink-resolved-ish path. Do not use `readlink -f` directly — it doesn't exist on macOS by default. Use `platform::realpath` from `lib/platform.sh` if you need full symlink resolution.

**Every sourced library** in `lib/` starts with the once-only guard pattern (the bootstrap also enforces this, but the guard makes files safe to source manually too):

```bash
# log.sh — logging helpers
[ "${__LOADED_log:-}" = 1 ] && return 0
__LOADED_log=1

log::info()  { printf '[INFO]  %s\n' "$*" >&2; }
log::warn()  { printf '[WARN]  %s\n' "$*" >&2; }
log::error() { printf '[ERROR] %s\n' "$*" >&2; }
log::die()   { log::error "$@"; exit 1; }
```

`return 0` is correct in a sourced file — it returns from the source, not exits the parent shell. `exit` would kill the calling script.

## Sourcing and module loading

The bootstrap (`lib/_bootstrap.sh`, full template in `assets/lib/_bootstrap.sh`) provides `bootstrap::load`, which sources modules idempotently:

```bash
# In bin/mytool, after sourcing _bootstrap.sh:
bootstrap::load log platform http config
```

Internals (read the asset file for the full version):

```bash
bootstrap::load() {
  local mod guard val
  for mod in "$@"; do
    # Only allow simple names so we can safely build a variable name.
    case "$mod" in
      *[!a-zA-Z0-9_]*) log::die "bootstrap::load: invalid module name '$mod'" ;;
    esac
    guard="__LOADED_${mod}"
    eval "val=\${$guard:-}"
    [ "$val" = "1" ] && continue
    # shellcheck disable=SC1090
    . "${LIB_DIR}/${mod}.sh"
  done
}
```

The `eval` is the Bash 3.2 substitute for `${!guard}` indirect expansion (which exists but is awkward when assigning). It's safe here because `$mod` is validated first.

## Function namespacing

Bash 3.2 allows `::` in function names — use `module::function`:

```bash
log::info()   { ... }
http::get()   { ... }
config::load(){ ... }
```

This makes `grep -rn 'http::' lib/` instantly tell you every callsite of the http module, and gives you a poor-person's namespace without any of the cost. Internal helpers within a module use a leading underscore: `http::_build_headers`.

Do not use the `function` keyword — it's a non-POSIX bashism with no benefit and slightly worse parser behavior. Always use `name() { ... }`.

## Platform abstraction

macOS uses BSD coreutils; Linux uses GNU. Centralize every difference in `lib/platform.sh` (full template in `assets/lib/platform.sh`). The most common pitfalls:

| Operation | macOS (BSD) | Linux (GNU) |
|---|---|---|
| In-place sed | `sed -i '' 's/x/y/' f` | `sed -i 's/x/y/' f` |
| Resolve symlink | `readlink f` (one level) | `readlink -f f` (full) |
| Date math | `date -j -v-1d` | `date -d 'yesterday'` |
| Base64 decode | `base64 -D` | `base64 -d` |
| Stat file size | `stat -f%z f` | `stat -c%s f` |
| `mktemp` template | suffix `.XXXXXX` allowed | required, but in different position |
| `find -E` (extended regex) | flag before path | use `-regextype posix-extended` |

Sample helpers (template has more):

```bash
platform::is_macos() { [ "$(uname -s)" = "Darwin" ]; }
platform::is_linux() { [ "$(uname -s)" = "Linux" ]; }

platform::sed_inplace() {
  local expr="$1"; shift
  if platform::is_macos; then sed -i '' "$expr" "$@"
  else sed -i "$expr" "$@"; fi
}

platform::file_size() {
  if platform::is_macos; then stat -f%z "$1"
  else stat -c%s "$1"; fi
}
```

If a feature truly is GNU-only and there's no BSD equivalent, install `coreutils` via Homebrew on macOS and call the `g`-prefixed names (`gdate`, `gsed`, `greadlink`) explicitly — but only as a last resort, and document the dependency in `README.md`.

## Bash 3.2 quick reference

The full mapping of Bash 4+ features to Bash 3.2 alternatives lives in **`references/bash3-gotchas.md`**. Read that file whenever you catch yourself reaching for any of these:

- Associative arrays → parallel indexed arrays, or namespaced variable names with `eval`
- `mapfile` → `while IFS= read -r line; do arr+=("$line"); done < file`
- `${var^^}` / `${var,,}` → `tr '[:lower:]' '[:upper:]'`
- `&>>` → `>>file 2>&1`
- `wait -n` → poll PIDs in a loop with `kill -0`
- Empty-array under `set -u` → `"${arr[@]+"${arr[@]}"}"`

The reference also covers `[[ =~ ]]` regex pattern storage (a real Bash 3.2 footgun), printf format-string portability, and `local` variable scope traps.

## Testing with bats-core

Use **bats-core** (`bats-core/bats-core` on GitHub — the maintained fork; the original `sstephenson/bats` is dead). It's the consensus shell test framework.

`test/log.bats`:

```bash
#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  LIB_DIR="${PROJECT_ROOT}/lib"
  . "${LIB_DIR}/_bootstrap.sh"
  bootstrap::load log
}

@test "log::info writes to stderr with [INFO] prefix" {
  run --separate-stderr log::info "hello"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$stderr" = "[INFO]  hello" ]
}

@test "log::die exits non-zero" {
  run log::die "boom"
  [ "$status" -ne 0 ]
}
```

Install on macOS via `brew install bats-core`; on Linux via the distro package or `npm install -g bats`. Run with `bats test/`.

## Linting and formatting

Both are non-negotiable in any serious shell project:

- **shellcheck** — `brew install shellcheck`. Run on every file in `bin/` and `lib/`. Configure via `.shellcheckrc` (template in assets) to set `shell=bash` for files without shebangs (i.e., the `lib/*.sh` files).
- **shfmt** — `brew install shfmt`. Use these flags consistently: `shfmt -i 2 -ci -bn -sr` (2-space indent, indent switch cases, binary-ops at start of next line, redirect operators followed by space). Add to your editor's format-on-save.

Wire both into the `Makefile` (template in assets) so `make lint`, `make fmt`, `make test` all work.

## CI

A minimal GitHub Actions workflow that exercises both platforms lives in `assets/github-workflows/ci.yml`. It runs shellcheck, shfmt --diff, and bats on `ubuntu-latest` and `macos-latest`. Always run on macOS — that's where Bash 3.2 will catch you.

## When working on an existing project

1. Check `bash --version` of the user's environment if uncertain.
2. Grep for Bash 4+ features before adding new code: `grep -rn 'declare -A\|mapfile\|readarray\|\${[a-zA-Z_]*\^\^}\|\${[a-zA-Z_]*,,}\|&>>\|coproc\|wait -n' bin/ lib/`. Anything that hits is either a bug or a feature you can confidently extend.
3. If the user's project has no `lib/_bootstrap.sh`, propose introducing the layout incrementally — extract one module at a time rather than rewriting everything in one pass. Greg specifically prefers minimal, surgical changes.
4. When adding a new module, mirror the conventions already in the project even if they differ from this skill — consistency within a project beats this skill's defaults.

## Output expectations

When generating code:

- Always include the strict-mode preamble in `bin/` scripts and the load guard in `lib/` files.
- Always namespace functions as `module::name`.
- Never silently use a Bash 4+ feature; if you genuinely need one, surface it explicitly to the user with the trade-off.
- Never use a GNU-only flag without routing through `lib/platform.sh`.
- Quote every variable expansion (`"$var"`, `"${arr[@]}"`) unless deliberately splitting.
- Prefer `printf` to `echo` always — `echo -e` and `echo -n` are non-portable.
