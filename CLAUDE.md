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

```bash
# Install all linting tools (markdownlint-cli, jsonlint, jq)
make install-tools

# Run all linting checks
make lint

# Fix auto-fixable linting issues
make lint-fix

# Individual linting commands
make lint-fish        # Lint Fish shell files
make lint-markdown    # Lint Markdown files  
make lint-json        # Lint JSON files
```

#### Manual Fish Commands

```fish
# Format all Fish files (required before commits)
find . -name "*.fish" -exec fish_indent --write {} \;

# Check formatting without modifying files
find . -name "*.fish" -exec fish_indent --check {} \;

# Validate Fish syntax
fish -n functions/*.fish completions/*.fish
```

### Installation/Testing

```bash
# Test plugin installation using Makefile
make test

# Test plugin installation in CI environment
make test-ci
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

- The plugin hooks into Fish's variable change system using `--on-variable PWD`
- Supports multiple Node.js version managers: nvm, fnm, volta, asdf
- Supports multiple file formats: `.nvmrc`, `.node-version`, `.tool-versions`, `package.json` engines.node
- Includes performance optimizations: caching, debouncing, directory exclusions
- Configurable features: silent mode, auto-install toggle, notifications, project-only mode
- Error handling includes checking if Node.js is available and graceful fallback when versions can't be switched
- The search for version files traverses up the directory tree until it finds one or reaches the root directory

## Code Quality Standards

- All Fish code must be formatted with `fish_indent` before committing
- Functions should include description flags (`-d "description"`)
- Use proper Fish conventions for variable scoping (`set -l`, `set -g`, `set -gx`)
- Include comprehensive error handling and input validation
- Follow Fish best practices for command substitution and string handling
