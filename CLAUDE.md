# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Fish shell plugin that automatically loads the correct Node.js version from `.nvmrc` files when
changing directories. The plugin uses Fisher as its package manager.

## Architecture

Core entrypoints:

- `nvm_auto_use.fish` — main function that triggers on directory changes (`--on-variable PWD`)
  and orchestrates the version switch
- `nvm_find_nvmrc.fish` — walks up the directory tree to locate `.nvmrc`, `.node-version`,
  `.tool-versions`, or `package.json` engines.node

Supporting modules under `functions/`:

- `nvm_compat_detect.fish` — detect available version managers (nvm, fnm, volta, asdf)
- `nvm_extract_version.fish` — parse a version string out of any supported file format
- `nvm_cache.fish` — XDG-compliant on-disk cache with TTL
- `nvm_async.fish` — non-blocking version/manager checks using Fish background jobs
- `nvm_security.fish` — version validation, vulnerability check, and security policies
- `nvm_recommendations.fish` — version/upgrade recommendations
- `nvm_doctor.fish` — diagnostics and auto-fix
- `nvm_error_recovery.fish` — fallback paths when a manager or network call fails
- `nvm_notify.fish` — desktop notifications (osascript / notify-send / terminal-notifier)
- `nvm_version_prompt.fish` — render the active Node.js version for prompt integration
- `nvm_auto_use_config.fish` / `nvm_auto_use_silent.fish` — runtime configuration

## Development Commands

### Linting and Code Quality

The project pins every npm-installed linter via `# renovate:` markers in
`Makefile` and runs them through `npx --yes <tool>@<version>`. CI and local
runs always use the same version; Renovate opens PRs on new releases.

```bash
# Install jq (the only system tool not auto-fetched at lint time)
make install-tools

# Run all linting checks (Fish, Markdown, Markdown tables, JSON, EditorConfig)
make lint

# Fix auto-fixable linting issues (Fish, Markdown, Markdown tables)
make lint-fix

# Individual linting commands
make lint-fish         # Lint Fish shell files (formatting + syntax)
make lint-markdown     # Lint Markdown files (markdownlint-cli, pinned)
make lint-md-tables    # Verify Markdown tables are column-aligned
make lint-json         # Lint JSON files (jq preferred, jsonlint fallback)
make lint-editorconfig # Check EditorConfig compliance
```

#### Supported Linting Tools

- **Fish shell**: `fish_indent` for formatting, `fish -n` for syntax validation
- **Markdown**: `markdownlint-cli` (style) + `markdown-table-formatter` (column
  alignment) — both pinned via `# renovate:` markers in `Makefile` and run via
  `npx --yes <tool>@<version>`
- **JSON**: `jq` preferred for validation; falls back to pinned `jsonlint` via
  `npx` when `jq` is not installed
- **EditorConfig**: `editorconfig-checker` (downloaded by
  `.github/install_editorconfig-checker.sh` to `$XDG_BIN_HOME` / `$HOME/bin` /
  `/usr/local/bin` / `./bin` when no system binary exists; pinned release tag
  via `EDITORCONFIG_CHECKER_VERSION`)

`make install-tools` only ensures `jq` is present; the npm-based tools
materialise on demand via `npx`, and `editorconfig-checker` is fetched the
first time `make lint-editorconfig` runs without a system binary.

#### Manual Fish Commands

```fish
# Format all Fish files (required before commits)
find . -name "*.fish" -exec fish_indent --write {} \;

# Check formatting without modifying files
find . -name "*.fish" -exec fish_indent --check {} \;

# Validate Fish syntax
fish -n functions/*.fish completions/*.fish
```

### Testing

```bash
# Run all tests (unit + integration)
tests/test_runner.fish

# Run specific test types
make test-unit        # Unit tests only
make test-integration # Integration tests only

# Test plugin installation
make test             # Local installation test
make test-ci          # CI environment test
```

#### Manual Installation Commands

```fish
# Install the plugin locally for testing
fisher install .

# Remove the plugin
fisher remove ivuorinen/nvm-auto-use.fish
```

### Configuration Commands

```fish
# View current configuration
nvm_auto_use_config

# Enable/disable features
nvm_auto_use_config silent on
nvm_auto_use_config auto_install off
nvm_auto_use_config manager fnm

# Set debounce timing
nvm_auto_use_config debounce 1000

# Exclude directories
nvm_auto_use_config exclude "build"
```

### Developer Tools

```fish
# Security and validation
nvm_security check_version "18.17.0"  # Validate version format and policies
nvm_security audit                    # Comprehensive security audit
nvm_security policy set min_version "16.0.0"  # Set security policies

# Smart recommendations
nvm_recommendations suggest_version new_project  # Get version recommendations
nvm_recommendations upgrade_path                 # Plan upgrade strategy
nvm_recommendations security_update              # Security-focused updates

# Diagnostics and debugging
nvm_doctor check           # Comprehensive health check
nvm_doctor system          # System information
nvm_doctor managers        # Check version managers
nvm_doctor fix all         # Auto-fix common issues

# Cache management
nvm_cache stats            # Cache statistics
nvm_cache clear            # Clear all cache
nvm_cache get "key"        # Get cached value

# Async operations
nvm_async version_check "file"  # Non-blocking version check
nvm_async cleanup              # Clean up background jobs

# Error recovery
nvm_error_recovery manager_failure "nvm" "18.0.0"  # Handle manager failures
```

### Testing the Functions

```fish
# Test the nvmrc finder function
nvm_find_nvmrc

# Test version extraction
nvm_extract_version .nvmrc

# Test directory change trigger (create a test .nvmrc file)
echo "18.0.0" > .nvmrc
cd .  # This should trigger nvm_auto_use

# Check version status
nvm_version_status
```

## Key Implementation Details

### Core Architecture

- The plugin hooks into Fish's variable change system using `--on-variable PWD`
- Supports multiple Node.js version managers: nvm, fnm, volta, asdf
- Supports multiple file formats: `.nvmrc`, `.node-version`, `.tool-versions`, `package.json` engines.node
- The search for version files traverses up the directory tree until it finds one or reaches the root directory

### Performance Features

- **XDG-compliant caching** with configurable TTL for version lookups and manager availability
- **Async operations** for non-blocking version checks using Fish background jobs
- **Debouncing** to prevent rapid version switching during directory navigation
- **Smart directory exclusions** to skip unnecessary processing

### Security & Reliability

- **Version validation** with format checking and policy enforcement
- **Security vulnerability scanning** with CVE checking (online and offline)
- **Error recovery mechanisms** with graceful degradation and fallback strategies
- **Input sanitization** to prevent injection attacks through version files

### Advanced Capabilities

- **Smart recommendations** for version selection, upgrades, and security updates
- **Comprehensive diagnostics** with the `nvm_doctor` command for troubleshooting
- **Extensive testing suite** with unit and integration tests
- **Configuration management** with persistent settings and policy enforcement

## Code Quality Standards

Behavioral mandates live under `.claude/rules/` (path-scoped where
applicable). See those files for the authoritative rule text.

### CI/CD Integration

- GitHub Actions runs all linting checks on push/PR
- Use `make test-ci` to test plugin installation in CI environments

### Tool Installation

- npm-based linters (`markdownlint-cli`, `jsonlint`, `markdown-table-formatter`)
  are not installed globally — they are pinned in `Makefile` via `# renovate:`
  markers and invoked through `npx --yes <tool>@<version>`
- `make install-tools` only installs `jq` (used as the preferred JSON validator)
- `editorconfig-checker` is downloaded by
  `.github/install_editorconfig-checker.sh` when no system binary exists; the
  installer respects XDG standards (`$XDG_BIN_HOME` → `$HOME/bin` →
  `/usr/local/bin` → `./bin` fallback) and uses `mktemp` for staging
