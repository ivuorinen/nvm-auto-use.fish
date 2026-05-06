---
paths:
  - "functions/**/*.fish"
---

# Module boundaries

Every file in `functions/*.fish` must define exactly one public function whose name equals the basename without `.fish`. Do not put additional public `nvm_*` functions in a file whose name does not match — Fisher's autoload contract relies on this mapping.
Public functions are `nvm_*`. Private helpers used only inside the same file are `_nvm_*`. Calling another file's `_nvm_*` helper from outside is a violation; promote it to a public subcommand on its module's manager function instead.
Manager-style entrypoints (functions that take an action verb as `$argv[1]`) must use a single top-level `switch $argv[1]` with a `case '*'` branch that prints a usage line and `return 1`. Never let an unknown subcommand fall through silently, including in private dispatcher helpers.
`_nvm_security_hash` is the canonical hasher for this codebase. Never call `shasum`, `sha1sum`, or `md5sum` directly — the portability fallback chain lives in `_nvm_security_hash`.
Only `nvm_auto_use` registers `--on-variable PWD`. Adding any other variable, signal, or event handler to a public function requires an inline comment explaining why.
When a public function spawns a `fish -c` subshell, pass values positionally via `-- "$arg1" "$arg2"` and validate any user-controlled identifier (manager name, version string, file path) against an allow-list before interpolation. Never embed unvalidated input into the subshell script body.
Every public `nvm_*` function should have a corresponding `tests/unit/test_<topic>.fish` or be exercised by `tests/integration/test_*.fish`. New public functions ship with their tests, not later.
