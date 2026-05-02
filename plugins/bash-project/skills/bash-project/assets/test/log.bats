#!/usr/bin/env bats
# test/log.bats — example bats-core test for the log module.
# Run with: bats test/

setup() {
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  LIB_DIR="${PROJECT_ROOT}/lib"
  # shellcheck source=../lib/_bootstrap.sh
  . "${LIB_DIR}/_bootstrap.sh"
  bootstrap::load log
}

@test "log::info writes to stderr at info level" {
  LOG_LEVEL=info run --separate-stderr log::info "hello"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [[ "$stderr" == *"[info] hello"* ]]
}

@test "log::debug is suppressed at default level" {
  LOG_LEVEL=info run --separate-stderr log::debug "noisy"
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
}

@test "log::debug shows when LOG_LEVEL=debug" {
  LOG_LEVEL=debug run --separate-stderr log::debug "noisy"
  [ "$status" -eq 0 ]
  [[ "$stderr" == *"[debug] noisy"* ]]
}

@test "log::die exits non-zero" {
  run log::die "boom"
  [ "$status" -eq 1 ]
}
