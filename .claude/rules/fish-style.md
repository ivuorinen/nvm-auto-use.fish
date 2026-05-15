---
paths:
  - "functions/**/*.fish"
  - "completions/**/*.fish"
  - "tests/**/*.fish"
---

# Fish shell style

Always run `fish_indent --write` on any Fish file before committing.
Always include `-d "<short description>"` on every `function` definition.
Use `set -l` for locals, `set -g` for module/process state, `set -gx` only when the value must be inherited by subshells.
Use anchored regex when stripping prefixes (e.g. `string replace -r '^v' ''`); never `string replace 'v' ''` — that strips every `v`.
Never call `shasum`, `sha1sum`, or `md5sum` directly; use `_nvm_security_hash` so the portability fallback chain stays in one place.
When passing values into a `fish -c` subshell, pass them positionally via `-- "$arg1" "$arg2"`. Never interpolate `$arg` directly into the script body — it opens a command-injection vector through file paths and version strings.
