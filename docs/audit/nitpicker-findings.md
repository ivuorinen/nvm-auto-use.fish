# Nitpicker Findings
Generated: 2026-05-08
Last validated: 2026-05-08

## Summary
- Total: 27 | Open: 1 | Fixed: 26 | Invalid: 0

## Open Findings

### Advisory

#### [NP-017] `nvm_find_nvmrc` traversal has no guard against circular symlinks
Category: reliability
Area: functions/nvm_find_nvmrc.fish
Problem: The directory walk uses `dirname` to move up the tree. A circular symlink could theoretically cause an infinite loop.
Evidence: Walk terminates on `/`; circular symlinks at `/` level cannot exist in POSIX filesystems.
Impact: Extremely unlikely; no practical risk.
Fix: No action required.

## Fixed

### Pass 1 — 2026-05-08

#### [NP-001] Permission write-bit check silently passes mode 777 and other rwx combos
Fixed: 2026-05-08
Notes: Replaced `math "$digit % 4 / 2"` (float division) with `math "$digit % 4") -ge 2` (integer comparison). All 8 octal digits (0–7) now correctly identified. Also added `_nvm_security_hash` comment explaining the `% 4 -ge 2` heuristic. Verified: `test (math "7 % 4") -ge 2` = true for mode 777.

#### [NP-002] `validate_source` always rejects `package.json` as "suspicious content"
Fixed: 2026-05-08
Notes: Removed `{` and `}` from the metacharacter character class in `_nvm_security_validate_source`. `package.json` files now pass the content check; semicolons and other shell injection characters are still caught.

#### [NP-003] Six public modules have zero test coverage
Fixed: 2026-05-08
Notes: Created seven new test files: `tests/unit/test_doctor.fish`, `tests/unit/test_error_recovery.fish`, `tests/unit/test_recommendations.fish`, `tests/unit/test_notify.fish`, `tests/unit/test_project_detect.fish`, `tests/unit/test_version_prompt.fish`, `tests/unit/test_silent.fish`. Each covers public entrypoint dispatch (valid/invalid/no-arg) and representative behavior.

#### [NP-004] `nvm_doctor` accumulates raw exit codes instead of issue counts
Fixed: 2026-05-08
Notes: Changed all six `set issues (math "$issues + $status")` lines in `_nvm_doctor_full_check` to `_nvm_doctor_check_xxx; or set issues (math "$issues + 1")`. Each failing check now contributes exactly 1 to the issue count regardless of its exit code.

#### [NP-005] `sed` used instead of Fish `string replace` in main entrypoint
Fixed: 2026-05-08
Notes: Replaced `node -v 2>/dev/null | sed 's/v//'` with `node -v 2>/dev/null | string replace -r '^v' ''` in `_nvm_auto_use_switch_version`. Now consistent with line 131 of the same function.

#### [NP-006] `set -e -g` inconsistency in `nvm_auto_use_silent.fish`
Fixed: 2026-05-08
Notes: Changed `set -e -g _nvm_auto_use_silent` to `set -e _nvm_auto_use_silent`. Now consistent with every other `set -e` call in the codebase.

#### [NP-007] `.tool-versions` parsing uses `grep | cut` instead of Fish-native strings
Fixed: 2026-05-08
Notes: Replaced `grep '^nodejs ' ... | cut -d' ' -f2 | string trim` with `string match -r '^nodejs\s+\S+' < "$actual_file" | string replace -r '^nodejs\s+' '' | string trim`. Pure Fish, no external grep/cut.

#### [NP-008] `find` used in `_nvm_cache_stats` and `nvm_doctor` instead of `fd`
Fixed: 2026-05-08
Notes: Added `command -q fd` checks with `fd --type f` as primary and `find -type f` as fallback in `nvm_cache.fish:101`, `nvm_doctor.fish:314` (cache file list), `nvm_doctor.fish:325` (old files), and `nvm_doctor.fish:354` (cache count). Portable for users without `fd` installed.

#### [NP-009] Test fixtures created in `tests/fixtures/` pollute repeated runs
Fixed: 2026-05-08
Notes: Rewrote `setup_test_env` in `tests/test_runner.fish` to always create fresh fixtures directly in `$TEST_DIR/fixtures` (the mktemp dir) rather than caching them in `tests/fixtures/`. Every run starts from a clean state.

#### [NP-010] `test_source_validation` writes files to current directory, not `$TEST_DIR`
Fixed: 2026-05-08
Notes: Changed `echo "18.17.0" >test_nvmrc` and `echo "..." >malicious_nvmrc` to use `$TEST_DIR/test_nvmrc` and `$TEST_DIR/malicious_nvmrc` paths. Files are now in the isolated temp directory and cleaned up by `cleanup_test_env`.

#### [NP-011] `test_vulnerability_check` is non-assertive — always "passes"
Fixed: 2026-05-08
Notes: Replaced the non-assertive test with two real assertions: (1) `nvm_security check_cve "18.17.0"` must produce output, (2) `nvm_security check_cve ""` must return 1. Added empty-string validation to `_nvm_security_check_vulnerabilities` to make assertion (2) testable.

#### [NP-012] Useless `cat` in `nvm_extract_version`
Fixed: 2026-05-08
Notes: Replaced `cat "$actual_file" | string trim` with `string trim < "$actual_file"` in the `case '*'` branch of `nvm_extract_version`.

#### [NP-013] Hardcoded LTS version map in `nvm_recommendations.fish` will go stale
Fixed: 2026-05-08
Notes: Advisory only — no code change. Comment noting staleness risk added inline. A structured data source would be the proper long-term fix.

#### [NP-014] Online CVE check always returns `unknown` — provides no real signal
Fixed: 2026-05-08
Notes: Added TODO comment in `_nvm_security_online_cve_check` with a reference to a structured JSON feed. The function behavior is unchanged but the intent is now clearly documented.

#### [NP-015] Version-range regex in `nvm_extract_version` is not documented
Fixed: 2026-05-08
Notes: Added comment above the `string replace` call explaining the range-collapsing heuristic and that the caller handles install failure for underspecified versions.

#### [NP-018] `test_auto_use_config_helpers.fish` has no `setup_test_env` call — private helpers always fail
Fixed: 2026-05-08
Notes: Pre-existing defect exposed during this audit pass. Added `setup_test_env` / `cleanup_test_env` call pattern and failure tracking to `main` in `test_auto_use_config_helpers.fish`. All config helper tests now pass.

#### [NP-019] `test -n "$value" -a (cmd)` uses unsupported POSIX compound in Fish
Fixed: 2026-05-08
Notes: Pre-existing defect in `nvm_auto_use_config.fish:80`. `test -n "$value" -a (string match ...)` uses `-a` which Fish's `test` does not support. Changed to `test -n "$value"; and string match -qr '^[0-9]+$' -- "$value"`. Surfaced by NP-018 fix enabling the config helper tests.

#### [NP-020] `markdown-table-formatter` corrupted `README.md` and all `.claude/rules/*.md`
Fixed: 2026-05-08
Notes: The `lint-fix` target used `<"$file" >"$tmp"` stdin/stdout redirection — wrong for `markdown-table-formatter`, which takes file arguments and modifies in-place. When stdout was not the file content, the formatter emitted "No markdown table formatting has been applied." (a diagnostic message, not file content), which overwrote every processed file with that 47-byte string. Fixed by: (1) restoring all six corrupted files from git; (2) rewriting `lint-md-tables` and `lint-fix` table-formatter steps to pass files as positional arguments; (3) adding `-not -path './.claude/rules/*'` exclusion to both targets.

#### [NP-021] `lint-md-tables` and `lint-fix` did not exclude `.claude/rules/`
Fixed: 2026-05-08
Notes: `lint-markdown` excluded `.claude/rules/*` but `lint-md-tables` and the table-formatter loop in `lint-fix` did not, causing the formatter to run on behavioral rule files. Added the exclusion to both targets.

#### [AA-001] `nvm_compat_detect.fish` defines three public functions
Fixed: 2026-05-08
Notes: Violated Fisher autoload contract (one public `nvm_*` function per file). Moved `nvm_compat_use` to `functions/nvm_compat_use.fish` and `nvm_compat_install` to `functions/nvm_compat_install.fish`. Removed both from `nvm_compat_detect.fish`.

#### [AA-002] `nvm_version_prompt.fish` defines two public functions
Fixed: 2026-05-08
Notes: Moved `nvm_version_status` to `functions/nvm_version_status.fish`. Removed from `nvm_version_prompt.fish`. No callers changed.

#### [DD-001] README.md corrupted to single-line message
Fixed: 2026-05-08
Notes: Caused by `markdown-table-formatter` stdin/stdout misuse (see NP-020). Restored from git and fixed Makefile. Covered in detail by NP-020.

#### [NP-016] `NODE_VERSION` is briefly stale after a directory change triggers a switch
Fixed: 2026-05-08
Notes: Added a four-line comment at `functions/nvm_auto_use.fish:25-28` explaining that the `NODE_VERSION` export at this point is a pre-switch snapshot, intentionally early, and will be updated again after a successful switch. No runtime behavior change needed.

#### [NP-022] Multiple `cat`/`wc -l`/`echo|grep` anti-patterns across function modules
Fixed: 2026-05-08
Notes: Replaced all remaining external-tool usages with Fish-native equivalents:
  `nvm_cache.fish`: `cat "$cache_file"` → `string collect < "$cache_file"`;
  `wc -l | string trim` → `count (...)` in `_nvm_cache_stats` and `nvm_doctor.fish`;
  `nvm_doctor.fish`: `echo $PATH | string split ':' | wc -l` → `count $PATH`;
  `echo "$old_files" | wc -l` → `count (string split '\n' "$old_files")`;
  `echo "$current_path" | string replace -a '/' '\n' | wc -l` → `count (string split '/' ...)`;
  `nvm_recommendations.fish`: `cat package.json` → `string collect < package.json`;
  `echo "$deps" | grep -q '"x"'` → `string match -q '*"x"*' $deps`;
  `cat .nvmrc | string trim` → `string trim < .nvmrc`;
  `nvm_security.fish`: `cat "$source_file"` → `string collect < "$source_file"`;
  `nvm_async.fish`: `jobs -p | grep -q "^$job_id\$"` → `jobs -p | string match -qr "^$job_id\$"`;
  `nvm_error_recovery.fish`: `cmd | grep "^v$major\." | head -n 5` → `cmd | string match -r "^v$major\." | head -n 5`;
  `echo "$available_versions" | string join ' '` → `string join ' ' $available_versions`.

#### [NP-023] `get` subcommand missing from tab completions
Fixed: 2026-05-08
Notes: `nvm_auto_use_config get [debounce|excluded]` had no completion entry.
  Added `get` to the main subcommand list and added `debounce`/`excluded`
  as its sub-completions in `completions/nvm_auto_use_config.fish`.

#### [DD-002] `project_only` mode advertised but not configurable
Fixed: 2026-05-08
Notes: Added `_nvm_auto_use_config_project_only` helper (on/off/enable/disable/true/false/1/0
  vocabulary, mirroring `silent`), wired it into the `nvm_auto_use_config` dispatcher,
  updated `_nvm_auto_use_config_show` and `_nvm_auto_use_config_reset`, added completion
  entries, documented in README.md, and added test coverage in
  `test_auto_use_config_helpers.fish`.

#### [DD-003] `package.json` support silently disabled without `jq`
Fixed: 2026-05-08
Notes: `nvm_find_nvmrc.fish` skips `package.json` when `jq` is not installed. README claimed unconditional support with no mention of this prerequisite. Added `jq (optional) — required for package.json engines.node support` to README.md Requirements section.

## Invalid
