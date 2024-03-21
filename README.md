# Bitcoin dev tooling

## justfile

[`just`](https://github.com/casey/just) is a command runner, like make.

### Setup

Simply install `just`, and copy the `justfile` into your bitcoin core source directory.
It can be named `justfile` or `.justfile` (to be "hidden") and can be added to .git/info/exclude so that git ignores it.

Alternatively, you can clone this repo somewhere, and create a new `.justfile` in your bitcoin core source directory.
Inside your own `justfile` you can import _this_ justfile, allowing you to override methods but still receive updates from this repo.

```bash
# clone the repo
git clone https://github.com/willcl-ark/bitcoin-dev-tools.git ~/src

# create new justfile and import this file into it
cat <<EOF > ~/src/bitcoin/.justfile
import? '~/src/bitcoin-dev-tools/justfile'

set allow-duplicate-recipes := true

[private]
default:
    just --list

EOF

# add .justfile to gitignore
echo ".justfile" >> ~/src/bitcoin/.git/info/exclude
```

### Usage

List commands with `just` (or `just --list`).

Add your own commands or contribute them back upstream here.
See the [manual](https://just.systems/man/en/chapter_1.html) for syntax and features.

Make sure to install the [completions](https://just.systems/man/en/chapter_65.html) for your shell!

Set your build command using the `$MAKE_CMD` environment variable.
I use `export MAKE_CMD="bear -- make"` so that a `compile_commands.json` is generated when compiling, which can then be used by [`clangd`](https://clangd.llvm.org/).

### Workflow

Typical usage for a user of this justfile might be:

1. Show main dependencies for your OS, installing them per the instructions:

    ```bash
    just show-deps
    ```

2. (optional) Install the python dependencies needed for linting:

    ```bash
    just install-python-deps
    ```

3. Compile the current branch with default configuration:

    ```bash
    just build
    ```

4. Check all tests are passing:

    ```bash
    just test
    ```

5. Run linters:

    ```bash
    just lint
    ```

6. Make some changes to the code...

7. Check all new commits in the branch are good, shortcut to run `just check` on each new commit in the branch vs master:

    ```bash
    just prepare
    ```
