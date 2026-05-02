# lib/log.sh — logging helpers
# Bash 3.2.57+ compatible.

[ "${__LOADED_log:-}" = 1 ] && return 0
__LOADED_log=1

# LOG_LEVEL: one of debug, info, warn, error. Defaults to info.
: "${LOG_LEVEL:=info}"

# Numeric levels for comparison.
log::_level_num() {
  case "$1" in
    debug) printf '0' ;;
    info)  printf '1' ;;
    warn)  printf '2' ;;
    error) printf '3' ;;
    *)     printf '1' ;;
  esac
}

log::_should_log() {
  local want cur
  want="$(log::_level_num "$1")"
  cur="$(log::_level_num "$LOG_LEVEL")"
  [ "$want" -ge "$cur" ]
}

# Use ISO-8601 timestamps. `date +%FT%T%z` is portable across BSD and GNU.
log::_emit() {
  local level="$1"; shift
  log::_should_log "$level" || return 0
  printf '%s [%s] %s\n' "$(date +%FT%T%z)" "$level" "$*" >&2
}

log::debug() { log::_emit debug "$@"; }
log::info()  { log::_emit info  "$@"; }
log::warn()  { log::_emit warn  "$@"; }
log::error() { log::_emit error "$@"; }

# log::die <message...> — log at error level and exit 1.
log::die() {
  log::error "$@"
  exit 1
}
