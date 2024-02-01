# Bitcoin dev tooling

## justfile

[`just`](https://github.com/casey/just) is a command runner, like make.

Simply install `just`, and copy the `justfile` into your source directory.
It can be named `justfile` or `.justfile` (to be "hidden") and can be added to .git/info/exclude so that git ignores it.

List commands with `just` (or `just --list`).

Add your own commands or contribute them back upstream here.
See the [manual](https://just.systems/man/en/chapter_1.html) for syntax and features.

Make sure to install the [completions](https://just.systems/man/en/chapter_65.html) for your shell!

Set your build command using the `$MAKE_CMD` environment variable.
I use `export MAKE_CMD="bear -- make"` so that a `compile_commands.json` is generated when compiling, which can then be used by [`clangd`](https://clangd.llvm.org/).

### Usage

Typical usage for a new user might there be:

1. Show main dependencies for your OS, installing them per the instructions:

    ```bash
    just show-deps
    ```

2. Install the python dependencies needed for linting:

    ```bash
    just install-python-deps
    ```

3. Compile the current branch with default configuration:

    ```bash
    just compile
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

7. Check the branch is good, run `just check` and `just format-commit` on each new commit in the branch:

    ```bash
    just full-check
    ```
