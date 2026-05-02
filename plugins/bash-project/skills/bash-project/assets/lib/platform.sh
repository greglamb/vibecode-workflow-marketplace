# lib/platform.sh — macOS/Linux abstraction layer
# Bash 3.2.57+ compatible.
# Always route OS-divergent operations through this file rather than
# branching on `uname` ad-hoc throughout the codebase.

[ "${__LOADED_platform:-}" = 1 ] && return 0
__LOADED_platform=1

# Cached uname so we don't fork for every check.
__PLATFORM_OS="$(uname -s)"

platform::os()       { printf '%s' "$__PLATFORM_OS"; }
platform::is_macos() { [ "$__PLATFORM_OS" = "Darwin" ]; }
platform::is_linux() { [ "$__PLATFORM_OS" = "Linux" ]; }
platform::is_bsd()   { case "$__PLATFORM_OS" in Darwin|FreeBSD|OpenBSD|NetBSD) return 0 ;; esac; return 1; }

# In-place sed. Pass the expression as $1, then file paths as $2..$N.
platform::sed_inplace() {
  local expr="$1"; shift
  if platform::is_bsd; then
    sed -i '' "$expr" "$@"
  else
    sed -i "$expr" "$@"
  fi
}

# Resolve a path to its canonical, symlink-free, absolute form.
# `readlink -f` is GNU-only; this is the portable equivalent.
platform::realpath() {
  local target="$1" dir base
  if [ -d "$target" ]; then
    (cd "$target" && pwd -P)
    return
  fi
  dir="$(dirname "$target")"
  base="$(basename "$target")"
  printf '%s/%s\n' "$(cd "$dir" && pwd -P)" "$base"
}

# File size in bytes.
platform::file_size() {
  if platform::is_bsd; then
    stat -f%z "$1"
  else
    stat -c%s "$1"
  fi
}

# File modification time as Unix epoch.
platform::file_mtime() {
  if platform::is_bsd; then
    stat -f%m "$1"
  else
    stat -c%Y "$1"
  fi
}

# Date arithmetic: yesterday's date as YYYY-MM-DD.
platform::yesterday() {
  if platform::is_bsd; then
    date -j -v-1d +%F
  else
    date -d 'yesterday' +%F
  fi
}

# Convert "YYYY-MM-DD" (or other format-string-able dates) to a Unix epoch.
# Usage: platform::date_to_epoch "2026-05-01" "%Y-%m-%d"
platform::date_to_epoch() {
  local input="$1" fmt="${2:-%Y-%m-%d}"
  if platform::is_bsd; then
    date -j -f "$fmt" "$input" +%s
  else
    date -d "$input" +%s
  fi
}

# Base64 decode (BSD uses -D, GNU uses -d).
platform::b64_decode() {
  if platform::is_bsd; then
    base64 -D
  else
    base64 -d
  fi
}

# Reverse-cat (line-reverse a file).
platform::tac() {
  if platform::is_bsd; then
    tail -r "$@"
  else
    tac "$@"
  fi
}

# Number of CPUs.
platform::nproc() {
  if platform::is_bsd; then
    sysctl -n hw.ncpu
  else
    nproc
  fi
}

# Portable mktemp directory. Always produces a real directory and prints its path.
platform::mktempdir() {
  local prefix="${1:-tmp}"
  mktemp -d "${TMPDIR:-/tmp}/${prefix}.XXXXXX"
}
