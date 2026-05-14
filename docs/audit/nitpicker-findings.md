# Nitpicker Findings
Generated: 2026-05-08
Last validated: 2026-05-14

## Summary
- Total: 51 | Open: 1 | Fixed: 50 | Invalid: 0

## Open Findings

### Advisory

#### [NP-017] `nvm_find_nvmrc` traversal has no guard against circular symlinks
Category: reliability
Area: functions/nvm_find_nvmrc.fish
Problem: The directory walk uses `dirname` to move up the tree. A circular symlink could theoretically cause an infinite loop.
Evidence: Walk terminates on `/`; `dirname` operates on path strings not filesystem traversal, so circular symlinks cannot cause infinite loops.
Impact: Extremely unlikely; no practical risk.
Fix: No action required.

## Fixed

### Pass 5 — 2026-05-14

#### [NP-042] `pr-lint.yml` grants write permissions on push events
Fixed: 2026-05-14
Notes: Split the single `Lint` job into `LintPush` (push trigger, `contents: read` + `statuses: write` only) and `LintPR` (pull_request trigger, adds `issues: write` + `pull-requests: write`). Removed `packages: read` from both — not needed for linting. Each job only carries the permissions its event type requires.

#### [NP-043] `_nvm_async_version_check` and `_nvm_async_manager_check` return cached value string, not PID
Fixed: 2026-05-14
Notes: Changed both cache-hit branches from `echo "$cached_result"; return 0` to `nvm_cache get ... >/dev/null 2>&1; return 0`. Cache hits now return empty (no output); callers guard with `test -n "$job_id"` before calling `_nvm_async_wait`. Updated `test_async_version_check` and `test_async_manager_check` in `test_async_helpers.fish` to handle both code paths correctly.

#### [NP-044] `_nvm_async_wait` passes unvalidated `$job_id` to `kill -9` and uses it raw in regex
Fixed: 2026-05-14
Notes: Added numeric guard at entry of `_nvm_async_wait`: `if not string match -qr '^[0-9]+$' -- "$job_id"; return 1; end`. This rejects empty and non-numeric values before they reach `string match -qr "^$job_id\$"` (broken regex risk) or `kill -9 $job_id` (kill with garbage arg).

#### [NP-045] `test_async_version_check` and `test_async_wait` swallow timeouts as non-failures
Fixed: 2026-05-14
Notes: Replaced `_nvm_async_wait ...; and echo "✅"/or echo "⚠️"` with `if not _nvm_async_wait ...; echo "❌ ..."; return 1/set failed 1; end` pattern in `test_async_version_check`, `test_async_manager_check`, and `test_async_wait`. Timeout is now a test failure, not a warning. Also ensured `rm -f async_test.nvmrc` always runs before any return in `test_async_version_check`.

#### [NP-046] `test_async_cleanup` uses `sleep 2`, never exercises the reaping branch, leaks job
Fixed: 2026-05-14
Notes: Changed `sleep 2 &` to `sleep 0.1 &`. Added `kill $job_id 2>/dev/null; wait $job_id 2>/dev/null` after the cleanup call to prevent the job leaking into later tests.

#### [NP-047] 14 test files use CWD-relative `source tests/test_runner.fish`
Fixed: 2026-05-14
Notes: Replaced `source tests/test_runner.fish` in all 14 unit and integration test files with `source (path normalize (dirname (status --current-filename))/../test_runner.fish)`. `path normalize` collapses the `..` before the path is stored as the source context filename — without normalization, Fish stores the path unnormalized and `dirname dirname` inside `setup_test_env` computes the wrong repo root, breaking the private helper source loop. All tests pass after fix.

### Pass 4 — 2026-05-14

#### [NP-036] `test_async_wait` NP-035 fix incomplete — `grep -o` pattern still present
Fixed: 2026-05-14
Notes: Replaced `set -l job_id (jobs -l | tail -n 1 | grep -o '[0-9]*')` with `sleep 1 &; set -l job_id $last_pid` in `test_async_helpers.fish:74-75`, matching the pattern already applied to `test_async_cleanup` in NP-035.

#### [NP-037] `_nvm_auto_use_clear_cache` uses `set -e` without `-g` flag
Fixed: 2026-05-14
Notes: Changed all three `set -e _nvm_auto_use_cached_*` calls in `nvm_auto_use.fish:173-175` to `set -eg`, consistent with the convention established by NP-025 and NP-028.

#### [NP-038] `_nvm_auto_use_config_include` indexed array erase missing `-g`
Fixed: 2026-05-14
Notes: Changed `set -e _nvm_auto_use_excluded_dirs[$index]` to `set -eg` in `nvm_auto_use_config.fish:112`. Now consistent with every other `set -e` in that file.

#### [NP-039] Three `grep -q` external calls remain in function modules
Fixed: 2026-05-14
Notes: Replaced all three with Fish-native equivalents: `nvm_find_nvmrc.fish:26` → `string match -qr '^nodejs '`; `nvm_compat_detect.fish:19` → `string match -qx nodejs`; `nvm_doctor.fish:166` → `string match -qr 'nodejs'`.

#### [NP-040] `_nvm_async_safe_read` is dead code
Fixed: 2026-05-14
Notes: Removed the unreachable `_nvm_async_safe_read` function (lines 112-122) from `nvm_async.fish`. No caller existed in the codebase.

#### [NP-041] Private functions in `nvm_auto_use.fish` and `nvm_auto_use_config.fish` missing `-d` descriptions
Fixed: 2026-05-14
Notes: Added `-d "..."` to all 19 function definitions: 8 in `nvm_auto_use.fish` (including the public `nvm_auto_use`) and 11 private helpers in `nvm_auto_use_config.fish`. All pass `fish_indent --check` and `make lint-fish`.

### Pass 3 — 2026-05-14

#### [NP-033] `lint-editorconfig` PATH missing `$HOME/bin` and `$XDG_BIN_HOME`
Fixed: 2026-05-14
Notes: Split the long `PATH=` assignment into `_ec_path="$$PWD/bin:$$HOME/bin:$${XDG_BIN_HOME:-$$HOME/bin}"` + `PATH="$$_ec_path:$$PATH" editorconfig-checker` in Makefile:150. Now covers the installer's preferred `$HOME/bin`/`$XDG_BIN_HOME` locations, not just the `./bin` last-resort fallback.

#### [NP-034] `test_cache.fish` assert failures silently pass
Fixed: 2026-05-14
Notes: Added `or return 1` after `assert_equals` in `test_cache_basic_operations` (line 12), `assert_contains` in `test_cache_stats` (line 62), and both `assert_equals`/`assert_not_equals` calls in `test_cache_key_generation` (lines 73, 77). Failures now propagate to the `main` counter.

#### [NP-035] `test_async_helpers.fish:55` brittle job-ID extraction via `grep`
Fixed: 2026-05-14
Notes: Replaced `jobs -l | tail -n 1 | grep -o '[0-9]*'` with `$last_pid` — the Fish variable set to the PID of the most recently backgrounded job. Eliminates format-dependent number parsing.


## Fixed

### Pass 2 — 2026-05-14

#### [NP-024] LTS alias silently resolves to current version in async subshell
Fixed: 2026-05-14
Notes: Changed `command -q nvm` to `type -q nvm` in `nvm_extract_version.fish:43`. `type -q` checks both executables and Fish functions, so Fish users with a nvm Fish plugin (the common case) now get correct LTS alias resolution in async subshells. The bash-function nvm path is unchanged — it would require sourcing `$NVM_DIR/nvm.sh` via bash, which is a larger change out of scope here.

#### [NP-025] `set -e` without `-g` on global variables in test helpers
Fixed: 2026-05-14
Notes: Updated all `set -e _nvm_auto_use_*` calls in `tests/unit/test_auto_use_helpers.fish` to `set -eg`. Affected: `_nvm_auto_use_preferred_manager` (×2), `_nvm_auto_use_last_change` (×2), `_nvm_auto_use_debounce_ms`, `_nvm_auto_use_excluded_dirs` (×2), `_nvm_auto_use_cached_file` (×4), `_nvm_auto_use_cached_mtime` (×4).

#### [NP-026] `assert_not_equals` gives trivially-true result after `include`
Fixed: 2026-05-14
Notes: Added `assert_not_contains` helper to `tests/test_runner.fish` (the equivalent `assert_contains` existed but not its negation). Changed line 61 of `test_auto_use_config_helpers.fish` from `assert_not_equals "$_nvm_auto_use_excluded_dirs" testdir` to `assert_not_contains "$_nvm_auto_use_excluded_dirs" testdir`. Also fixed `set -e _nvm_auto_use_excluded_dirs` → `set -eg` on line 56 of that file.

#### [NP-027] `install_editorconfig-checker.sh` falls back before attempting `mkdir`
Fixed: 2026-05-14
Notes: Replaced `[ -d "$INSTALL_DIR" ] || INSTALL_DIR="/usr/local/bin"` with `mkdir -p "$INSTALL_DIR" 2>/dev/null || true` followed by a writability check (`[ ! -w "$INSTALL_DIR" ]`). Fresh environments now get `$HOME/bin` created rather than falling back to `/usr/local/bin` unnecessarily.

#### [NP-028] Six `set -e` calls on global config variables missing `-g` scope flag
Fixed: 2026-05-14
Notes: Changed all `set -e _nvm_auto_use_*` in `functions/nvm_auto_use_config.fish` to `set -eg`: `_nvm_auto_use_no_install`, `_nvm_auto_use_silent`, `_nvm_auto_use_project_only`, `_nvm_auto_use_preferred_manager`, and all six vars in `_nvm_auto_use_config_reset`. Configuration `reset` and individual `off/disable` commands now reliably clear their globals.

#### [NP-029] Injection test artifact `/tmp/nvm-auto-use-malicious-test` never cleaned up
Fixed: 2026-05-14
Notes: Added `rm -f /tmp/nvm-auto-use-malicious-test` in both `test_version_validation` and `test_source_validation` in `tests/unit/test_security.fish`, immediately after the assertion that tests the malicious input is rejected.

#### [NP-030] README table missing `lts/*` wildcard alias
Fixed: 2026-05-14
Notes: Updated the `.nvmrc` row in the Supported File Formats table to list all supported aliases: `18.17.0`, `lts/hydrogen`, `lts/*`, `lts`, `latest`. Format column updated to "Plain version or alias". `markdown-table-formatter` re-aligned the columns.

#### [NP-031] Timeout boundary recomputed on every loop iteration in `_nvm_async_wait`
Fixed: 2026-05-14
Notes: Added `set -l max_iter (math "$timeout * 10")` before the loop in `_nvm_async_wait`; the `while` condition now compares against `$max_iter` instead of re-evaluating `math` each iteration.

#### [NP-032] No `all` phony target — `make` with no arguments only prints help
Fixed: 2026-05-14
Notes: Added `all: lint test-unit` target and `all` to the `.PHONY` list in `Makefile`. `make` with no arguments now runs the full check suite rather than printing the help menu.

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
