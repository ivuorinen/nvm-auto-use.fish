# Documentation Audit Findings
Generated: 2026-05-08
Last validated: 2026-05-08

## Summary
- Total: 3 | Open: 0 | Fixed: 3 | Invalid: 0

## Open Findings

## Fixed

### Pass 1 — 2026-05-08

#### [DD-001] README.md and all .claude/rules/*.md corrupted to single-line message
Fixed: 2026-05-08
Notes: `make lint-fix` ran `markdown-table-formatter` against `.claude/rules/*.md`
  and `README.md`. The formatter outputs "No markdown table formatting has been
  applied." to stdout (and exits 0) on files with no Markdown tables, causing
  the Makefile's `<"$file" >"$tmp" && mv "$tmp" "$file"` pattern to overwrite
  all six files with that single-line message.
  Fixed by: (1) restoring all six files from their last clean git commit via
  `git show <sha>:<path>`; (2) adding `-not -path './.claude/rules/*'` to the
  `lint-md-tables` and `lint-fix` table-formatter loops in `Makefile` so these
  files are excluded in all future runs.

#### [DD-002] `project_only` mode advertised but not configurable
Fixed: 2026-05-08
Notes: Added `_nvm_auto_use_config_project_only` helper and `project_only`
  case to `nvm_auto_use_config`. Updated `_nvm_auto_use_config_show` to
  display project_only status, added `project_only` to `_nvm_auto_use_config_reset`,
  added completion entries, and documented the new option in README.md
  Configuration section.

#### [DD-003] `package.json` support silently disabled without `jq`
Fixed: 2026-05-08
Notes: `nvm_find_nvmrc.fish` skips `package.json` when `jq` is not installed
  (the `command -q jq` guard at line 17). README Quick Start example
  (`echo '{"engines":...}' > package.json; cd .`) and the Supported File
  Formats table both claim package.json support unconditionally with no mention
  of the jq prerequisite.
  Fixed by adding a note to README.md "Requirements" section: `jq` is required
  for `package.json` engines.node support.

## Invalid
