set dotenv-load := true
set shell := ["bash", "-uc"]

make_cmd := env('MAKE_CMD', 'bear  --config src/.bear-tidy-config -- make -j `nproc`')
os := os()

alias bm := build-min
alias rb := rebuild-min
alias c := check
alias b := build

######################
###### recipes #######
######################

[private]
default:
    just --list

# Full configure with --enable-debug and optional <args>
[group('build')]
configure *args:
    #!/usr/bin/env bash
    if [ ! -f ./configure ]; then
    ./autogen.sh
    fi
    ./configure --enable-debug {{ args }}

# Minimal configure with --enable-debug and optional <args>
[private]
configure-min *args:
    #!/usr/bin/env bash
    if [ ! -f ./configure ]; then
    ./autogen.sh
    fi
    ./configure --disable-bench --without-gui --disable-fuzz --disable-fuzz-binary --without-utils --enable-util-cli --enable-debug --with-incompatible-bdb {{ args }}

# Make helper
[private]
make:
    {{ make_cmd }}

# make-min helper
[private]
make-min:
    {{ make_cmd }} -C src bitcoind bitcoin-cli

# Make clean helper
[private]
make-clean:
    {{ make_cmd }} clean || true

# Clean, configure and build bitcoind and bitcoin-cli
[group('build')]
build-min: make-clean configure-min make-min

# Remake bitcoind and bitcoin-cli only using current configuration
[group('build')]
rebuild-min: make-min

# Clean, configure and build everything
[group('build')]
build: make-clean configure make

# make clean and make check
[private]
make-check:
    {{ make_cmd }} clean
    {{ make_cmd }} check

# Run all functional tests
[private]
test-func-all:
    test/functional/test_runner.py --jobs=`nproc`

# Run all unit tests
[private]
test-unit-all:
    {{ make_cmd }} check

# Run all unit and functional tests
[group('test')]
test: test-unit-all test-func-all

# Run a single functional test (filename.py)
[group('test')]
test-func test:
    test/functional/test_runner.py {{ test }}

# Run a single unit test suite
[group('test')]
test-unit suite:
    test_bitcoin --log_level=all --run_test={{ suite }}

# Run clang-format-diff on top commit
[no-exit-message]
[private]
format-commit:
    git diff -U0 HEAD~1.. | ./contrib/devtools/clang-format-diff.py -p1 -i -v

# Run clang-format on the diff (must be configured with clang)
[no-exit-message]
[private]
format-diff:
    git diff | ./contrib/devtools/clang-format-diff.py -p1 -i -v

# Run clang-tidy on top commit
[no-exit-message]
[private]
tidy-commit:
    git diff -U0 HEAD~1.. | ( cd ./src/ && clang-tidy-diff-17.py -p2 -j $(nproc) )

# Run clang-tidy on the diff (must be configured with clang)
[no-exit-message]
[private]
tidy-diff:
    git diff | ( cd ./src/ && clang-tidy-diff-17.py -p2 -j $(nproc) )

# Run the linter
[group('lint')]
lint:
    #!/usr/bin/env bash
    # use subshell to load any python venv for flake8
    cd test/lint/test_runner/
    cargo fmt
    cargo clippy
    COMMIT_RANGE="$( git rev-list --max-count=1 --merges HEAD )..HEAD" cargo run

# Run all linters, clang-format and clang-tidy on top commit
[group('lint')]
lint-commit: lint
    just format-commit
    just tidy-commit

# Run all linters, clang-format and clang-tidy on diff
[group('lint')]
lint-diff: lint
    just format-diff
    just tidy-diff

# Lint (top commit), build and test
[group('build')]
[group('test')]
[group('lint')]
check: lint-commit configure make-check test-func-all

# Interactive rebase current branch from (git merge-base) (`just rebase -i` for interactive)
[confirm("Warning, unsaved changes may be lost. Continue?")]
[no-exit-message]
[group('build')]
rebase *args:
    git rebase {{ args }} `git merge-base HEAD upstream/master`

# Update upstream/master and interactive rebase on it (`just rebase-master -i` for interactive)
[confirm("Warning, unsaved changes may be lost. Continue?")]
[group('build')]
rebase-upstream *args:
    git fetch upstream
    git rebase {{ args }} `git merge-base HEAD upstream/master`

# Check each commit in the branch passes `just lint`
[confirm("Warning, unsaved changes may be lost. Continue?")]
[no-exit-message]
[private]
rebase-lint:
    git rebase -i `git merge-base HEAD upstream/master` \
    --exec "just lint" \

# Check each commit in the branch passes `just check`
[confirm("Warning, unsaved changes may be lost. Continue?")]
[no-exit-message]
prepare:
    git rebase -i `git merge-base HEAD upstream/master` \
    --exec "just check" \

# Git range-diff from <old-rev> to HEAD~ against master
[no-exit-message]
[group('tools')]
range-diff old-rev:
    git range-diff master {{ old-rev }} HEAD~

# Profile a running bitcoind for 60 seconds (e.g. just profile `pgrep bitcoind`). Outputs perf.data
[no-exit-message]
[group('tools')]
profile pid:
    perf record -g --call-graph dwarf --per-thread -F 140 -p {{ pid }} -- sleep 60

# Run benchmarks
[group('tools')]
bench:
    src/bench/bench_bitcoin

# Verify scripted diffs from master to HEAD~
[group('tools')]
verify-scripted-diff:
    test/lint/commit-script-check.sh origin/master..HEAD

# Install python deps from ci/lint/install.sh
[group('tools')]
install-python-deps:
    awk '/^\$\{CI_RETRY_EXE\} pip3 install \\/,/^$/{if (!/^\$\{CI_RETRY_EXE\} pip3 install \\/ && !/^$/) print}' ci/lint/04_install.sh \
        | sed 's/\\$//g' \
        | xargs pip3 install
    pip3 install vulture # currently unversioned in our repo
    pip3 install requests # only used in getcoins.py

deps_command := if os == "linux" { "xdg-open https://github.com/bitcoin/bitcoin/blob/master/doc/build-unix.md" } else { if os == "macos" { "open https://github.com/bitcoin/bitcoin/blob/master/doc/build-osx.md" } else { if os == "windows" { "explorer https://github.com/bitcoin/bitcoin/blob/master/doc/build-windows.md" } else { if os == "freebsd" { "xdg-open https://github.com/bitcoin/bitcoin/blob/master/doc/build-freebsd.md" } else { "echo see https://github.com/bitcoin/bitcoin/tree/master/doc#building for build instructions" } } } }

# Show project dependencies in browser
[group('tools')]
show-deps:
    {{ deps_command }}

# Build depends
[group('build')]
build-depends:
    echo "Detected arch: .... {{ arch() }}"
    echo "Detected os: ...... {{ os() }}"
    cd depends && make -j`nproc`
    echo
    echo To use, run configure using your host triplet, e.g.:
    echo \"CONFIG_SITE=$PWD/depends/x86_64-pc-linux-gnu/share/config.site ./configure\"
    echo
    echo For available host-triplets see: https://github.com/bitcoin/bitcoin/tree/master/depends
