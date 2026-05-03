# Agent Guidelines

## Project

pilot.nvim is a Neovim plugin that lets users run, build, or test projects and
files via a JSON configuration file (called a pilot file). It supports
placeholder interpolation, custom executors, and multiple targets (e.g.
`project`, `file_type`).

At first, please always check README.md for the required Neovim version.
Always use the new provided APIs rather than the legacy ones.

## Testing

```bash
make test
```

## Code Style

- No code comments unless required by a linter.
- Use `vim.validate` for type checks on config/argument values.
- Use `vim.iter` instead of plain `for` loops over tables where appropriate.
- Error messages format:
  `"pilot.nvim: <lowercase message without trailing period>"`
- `print()` messages follow the same prefix format.

## Explore First

Before writing or editing any code, look at how similar files are done in the
project. Follow the same patterns, naming conventions, and style.

## Keep Test Files in Sync

When modifying a source file, update its corresponding test file if behaviour,
exports, or function signatures change. Do not leave stale or missing coverage.
Do not add trivial tests (e.g. checking that a module loads).
