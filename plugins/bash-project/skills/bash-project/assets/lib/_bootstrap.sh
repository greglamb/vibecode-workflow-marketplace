# lib/_bootstrap.sh — module loader for portable Bash projects
# Sourced by bin/* entry points; never executed directly.
# Bash 3.2.57+ compatible.

[ "${__LOADED__bootstrap:-}" = 1 ] && return 0
__LOADED__bootstrap=1

# Resolve LIB_DIR if the caller didn't set it.
: "${LIB_DIR:?bootstrap: LIB_DIR must be set by the caller}"

# bootstrap::load <module> [<module> ...]
#
# Sources lib/<module>.sh once, regardless of how many times it's called.
# Module names must be plain identifiers (a-z, A-Z, 0-9, _).
bootstrap::load() {
  local mod guard val
  for mod in "$@"; do
    case "$mod" in
      ''|*[!a-zA-Z0-9_]*)
        printf '[bootstrap] invalid module name: %s\n' "$mod" >&2
        return 1
        ;;
    esac

    guard="__LOADED_${mod}"
    eval "val=\${$guard:-}"
    [ "$val" = "1" ] && continue

    if [ ! -f "${LIB_DIR}/${mod}.sh" ]; then
      printf '[bootstrap] module not found: %s/%s.sh\n' "$LIB_DIR" "$mod" >&2
      return 1
    fi

    # shellcheck disable=SC1090
    . "${LIB_DIR}/${mod}.sh"
    # The sourced file should set its own __LOADED_<mod>=1 guard.
    # If it didn't, set one here so we don't re-source it.
    eval "val=\${$guard:-}"
    [ "$val" = "1" ] || eval "${guard}=1"
  done
}

# bootstrap::require_bash_version <major.minor>
#
# Aborts if the running Bash is older than the required version.
# By default this skill targets 3.2 — call this with "3.2" if you want
# an explicit guard, or with a higher number if a specific tool requires it.
bootstrap::require_bash_version() {
  local required="$1"
  local req_major="${required%%.*}"
  local req_minor="${required##*.}"
  local cur_major="${BASH_VERSINFO[0]}"
  local cur_minor="${BASH_VERSINFO[1]}"

  if [ "$cur_major" -lt "$req_major" ] \
    || { [ "$cur_major" -eq "$req_major" ] && [ "$cur_minor" -lt "$req_minor" ]; }; then
    printf 'This script requires Bash %s or newer (running %s.%s).\n' \
      "$required" "$cur_major" "$cur_minor" >&2
    exit 1
  fi
}

# Load the universally-needed modules. Keep this list short — anything
# project-specific should be loaded by bin/* entry points instead.
bootstrap::load log platform
