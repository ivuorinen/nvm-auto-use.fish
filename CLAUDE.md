# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Fish shell plugin that automatically loads the correct Node.js version from `.nvmrc` files when
changing directories. The plugin uses Fisher as its package manager.

## Architecture

The plugin consists of two main Fish functions:

- `nvm_auto_use.fish` - Main function that triggers on directory changes (`--on-variable PWD`) and handles
  the automatic Node.js version switching
- `nvm_find_nvmrc.fish` - Utility function that searches for `.nvmrc` files in the current directory and parent directories

## Development Commands

### Linting and Code Quality

The project uses a comprehensive linting setup with automatic tool installation:

```bash
# Install all linting tools (markdownlint-cli, jsonlint, jq, editorconfig-checker)
make install-tools

# Run all linting checks (Fish, Markdown, JSON, EditorConfig)
make lint

# Fix auto-fixable linting issues
make lint-fix

# Individual linting commands
make lint-fish         # Lint Fish shell files (formatting + syntax)
make lint-markdown     # Lint Markdown files (style, headers, lists)
make lint-json         # Lint JSON files (syntax validation)
make lint-editorconfig # Check EditorConfig compliance (line endings, indentation)
```

#### Supported Linting Tools

- **Fish shell**: `fish_indent` for formatting, `fish -n` for syntax validation
- **Markdown**: `markdownlint-cli` with custom configuration (`.markdownlint.json`)
- **JSON**: `jsonlint` or `jq` for syntax validation
- **EditorConfig**: `editorconfig-checker` (auto-installed if missing)

The linting system automatically downloads missing tools and follows XDG standards for installation.

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

### Fish Shell Code

- All Fish code must be formatted with `fish_indent` before committing
- Functions should include description flags (`-d "description"`)
- Use proper Fish conventions for variable scoping (`set -l`, `set -g`, `set -gx`)
- Include comprehensive error handling and input validation
- Follow Fish best practices for command substitution and string handling

### General Standards

- **Makefile**: 80-character line limit, tab indentation
- **Markdown**: 120-character line limit, consistent heading structure
- **JSON**: Valid syntax, proper formatting
- **EditorConfig**: Consistent line endings (LF), final newlines, no trailing whitespace

### CI/CD Integration

- GitHub Actions automatically runs all linting checks on push/PR
- All linting must pass before merging
- Use `make test-ci` for testing plugin installation in CI environments

### Tool Installation

- Missing linting tools are automatically installed during `make install-tools`
- Installation respects XDG standards: `$XDG_BIN_HOME` → `$HOME/bin` → `/usr/local/bin`
- Uses secure temporary directories (`mktemp`) for downloads
