set dotenv-load := true

make_command := env('MAKE_CMD', 'make')

[private]
alias cs := compile-slim
[private]
alias ms := make-slim

######################
###### recipes #######
######################

[private]
default:
    just --list

# Full configure with optional <args>
configure *args:
    ./autogen.sh
    ./configure --enable-debug {{ args }}

# Minimal configure
[private]
configure-slim:
    ./autogen.sh
    ./configure --without-bdb --without-miniupnpc --without-natpmp --disable-bench --without-gui --enable-debug

# Make current configuration
make:
    {{ make_command }} -j`nproc`

# Make bitcoind and bitcoin-cli only (faster)
[private]
make-slim:
    {{ make_command }} -j`nproc` -C src bitcoind bitcoin-cli

[private]
make-check:
    {{ make_command }} -j`nproc` clean
    {{ make_command }} -j`nproc` check

# Clean default compile with --enable-debug
compile: configure make-check

# Clean minimal compile with --enable-debug
[private]
compile-slim: configure-slim make-check

# Run all functional tests
[private]
test-func-all:
    test/functional/test_runner.py --jobs=`nproc`

# Run all unit tests
[private]
test-unit-all:
    {{ make_command }} -j`nproc` check

# Run all unit and functional tests
test: test-unit-all test-func-all

# Run a single functional test (filename.py)
test-func test:
    test/functional/test_runner.py {{ test }}

# Run a single unit test suite
test-unit suite:
    test_bitcoin --log_level=all --run_test={{ suite }}

# Run all linters
lint:
    #!/usr/bin/env bash
    # use subshell to load any python venv for flake8
    cd test/lint/test_runner/
    cargo fmt
    cargo clippy
    cargo run

# Run clang-format-diff on top commit
[no-exit-message]
format-commit:
    git diff -U0 HEAD~1.. | ./contrib/devtools/clang-format-diff.py -p1 -i -v

# Lint, build and test
check: lint compile test-func-all

# Run clang-tidy-diff on changed lines
[no-exit-message]
tidy:
    ./autogen.sh
    ./configure CC=clang CXX=clang++
    make clean && bear --config src/.bear-tidy-config -- make -j `nproc`
    git diff | ( cd ./src/ && clang-tidy-diff -p2 -j $(nproc) )

# Interactive rebase current branch from (git merge-base) (`just rebase -i` for interactive)
[no-exit-message]
[confirm("Warning, unsaved changes may be lost. Continue?")]
rebase *args:
    git rebase {{ args }} `git merge-base HEAD upstream/master`

# Update upstream/master and interactive rebase on it (`just rebase-master -i` for interactive)
[confirm("Warning, unsaved changes may be lost. Continue?")]
rebase-master *args:
    git fetch upstream
    git rebase {{ args }} `git merge-base HEAD upstream/master`

# Check each commit in the branch passes `check` & `format-commit`
[no-exit-message]
[confirm("Warning, unsaved changes may be lost. Continue?")]
full-test:
    git rebase -i `git merge-base HEAD upstream/master` \
    --exec "just check" \
    --exec "just format-commit"

# Git range-diff from <old-rev> to HEAD~ against master
[no-exit-message]
range-diff old-rev:
    git range-diff master {{ old-rev }} HEAD~

# Profile a running bitcoind for 60 seconds (e.g. just profile `pgrep bitcoind`). Outputs perf.data
[no-exit-message]
profile pid:
    perf record -g --call-graph dwarf --per-thread -F 140 -p {{ pid }} -- sleep 60

# Run benchmarks
bench:
    src/bench/bench_bitcoin

# Fetch lastest (force) push of current branch and apply it
[confirm("Warning, unsaved changes may be lost. About to `git reset --hard FETCH_HEAD`. Continue?")]
fetch:
    git fetch
    git reset --hard FETCH_HEAD
