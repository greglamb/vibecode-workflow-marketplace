# Makefile — portable Bash project automation.
# Targets: lint, fmt, fmt-check, test, all.

SHELL := /usr/bin/env bash

# All shell sources: bin/* (no extension) and lib/*.sh, test/*.bats.
SH_SOURCES := $(shell find bin lib -type f \( -name '*.sh' -o -path 'bin/*' \) 2>/dev/null)
BATS_FILES := $(shell find test -type f -name '*.bats' 2>/dev/null)

SHFMT_FLAGS := -i 2 -ci -bn -sr

.PHONY: all lint fmt fmt-check test clean

all: lint fmt-check test

lint:
	@command -v shellcheck >/dev/null || { echo "shellcheck not installed"; exit 1; }
	shellcheck --shell=bash $(SH_SOURCES)

fmt:
	@command -v shfmt >/dev/null || { echo "shfmt not installed"; exit 1; }
	shfmt $(SHFMT_FLAGS) -w $(SH_SOURCES)

fmt-check:
	@command -v shfmt >/dev/null || { echo "shfmt not installed"; exit 1; }
	shfmt $(SHFMT_FLAGS) -d $(SH_SOURCES)

test:
	@command -v bats >/dev/null || { echo "bats-core not installed"; exit 1; }
	bats $(BATS_FILES)

clean:
	rm -rf .tmp/ build/
