# Architecture Profile
Generated: 2026-05-08

## Detected Patterns

### Plugin / Extension (Fisher Autoload Contract) — High confidence
Evidence:
- Every `functions/*.fish` defines exactly one public function whose name equals
  the file basename (Fisher's autoload rule); all other helpers are `_nvm_*` private.
- `fishfile` declares upstream Fisher dependencies.
- `completions/nvm_auto_use_config.fish` follows Fish's per-command completion convention.
- `.claude/rules/module-boundaries.md` codifies the one-public-function-per-file rule.

### Pipe and Filter — High confidence
Evidence:
- `nvm_auto_use --on-variable PWD` is the pipeline source (event trigger).
- Execution flows through discrete, single-purpose stages in strict order:
  1. `_nvm_auto_use_should_debounce` — gate: suppress rapid fires
  2. `_nvm_auto_use_is_excluded_dir` — gate: skip excluded paths
  3. `nvm_project_detect` (optional) — gate: project-only mode
  4. `nvm_find_nvmrc` — locate version file
  5. `_nvm_auto_use_is_cache_valid` — gate: skip if already current
  6. `nvm_extract_version` — parse version from file
  7. `_nvm_auto_use_select_manager` → `nvm_compat_detect` — select runtime
  8. `nvm_compat_use` — apply version
  9. `nvm_notify` — output notification
- Each stage passes a single value forward; stages do not call each other
  (no cross-stage coupling).

### Command Dispatcher (Manager-style) — High confidence
Evidence:
- All non-pipeline public functions (`nvm_cache`, `nvm_security`,
  `nvm_doctor`, `nvm_recommendations`, `nvm_error_recovery`, `nvm_async`,
  `nvm_auto_use_config`) accept an action verb as `$argv[1]` and dispatch
  via `switch $action; case ...; case '*' echo "Usage: ..."; return 1; end`.
- This pattern is mandated in `.claude/rules/module-boundaries.md`.

### Event-Driven (single event) — Medium confidence
Evidence:
- `nvm_auto_use` registers `--on-variable PWD`, making it purely reactive to
  directory changes — the only cross-cutting runtime trigger.
- No other event or signal handler is registered (confirmed by grep of all
  `functions/*.fish`).
- Confidence is Medium because only one event is involved; a full event-driven
  architecture would have multiple producers/consumers and an event bus.

## Detected Combination

**Custom: Plugin/Fisher + Pipe-and-Filter + Command Dispatcher**

No standard compound architectural pattern (DDD, Hexagonal, Clean Architecture,
CQRS, etc.) applies. The codebase is a Fish shell plugin whose structure is
determined by Fisher's autoload contract and Fish's event system rather than
by application-layer architectural patterns.

## Inferred Structural Rules

1. **One public function per file.** Each `functions/*.fish` exposes exactly
   one `nvm_*` function. Private helpers are `_nvm_*` and are not called from
   outside the file that defines them.
2. **Manager-style dispatch.** Every multi-subcommand public function uses a
   single top-level `switch $argv[1]` with a `case '*'` fallback that prints a
   usage line and returns 1. No silent fall-through.
3. **Pipeline gate ordering.** Gates (debounce, exclude, project-only, cache)
   must appear before any I/O work (file walk, version extraction, manager call)
   in `nvm_auto_use`. Reordering gates changes correctness and performance.
4. **Single event registration.** Only `nvm_auto_use` may register
   `--on-variable PWD`. Any additional event handler requires an inline comment.
5. **No cross-module private calls.** A `_nvm_*` helper is private to its
   defining file. Cross-module private calls violate the autoload boundary.
6. **Cross-cutting modules are standalone.** `nvm_security`, `nvm_doctor`,
   `nvm_recommendations`, `nvm_error_recovery` are not called from the core
   pipeline; they are user-invoked tools. Injecting calls to them into
   `nvm_auto_use` would couple the fast path to slow or network-dependent logic.
7. **Hasher indirection.** `_nvm_security_hash` is the canonical hasher; no
   module calls `shasum`/`sha1sum`/`md5sum` directly.
8. **XDG cache isolation.** All on-disk cache operations go through
   `nvm_cache`; no module writes directly to `~/.cache`.

## Ambiguities & Contradictions

- `_nvm_auto_use_is_cache_valid` is an in-memory cache (global variables
  `_nvm_auto_use_cached_file` / `_nvm_auto_use_cached_mtime`) embedded in
  `nvm_auto_use.fish`, while `nvm_cache` is the XDG on-disk cache. The two
  caching layers serve different purposes but share no abstraction boundary —
  a caller cannot tell which layer is active without reading both files.
- `_nvm_auto_use_project_only` is checked in `nvm_auto_use.fish` but there
  is no `nvm_auto_use_config project_only` subcommand, leaving this feature
  undiscoverable through the documented configuration interface (see DD-002).
