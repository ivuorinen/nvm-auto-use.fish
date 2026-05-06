# nvm-auto-use.fish

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fivuorinen%2Fnvm-auto-use.fish.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fivuorinen%2Fnvm-auto-use.fish?ref=badge_shield)

Intelligent Node.js version management for Fish shell with automatic version switching, multi-manager support,
and extensive configuration options.

## Installation

Ensure you have [fisher](https://github.com/jorgebucaran/fisher) installed, then run:

```fish
fisher install ivuorinen/nvm-auto-use.fish
```

## Features

### 🚀 **Automatic Version Switching**

- Detects Node.js version files when changing directories
- Supports multiple file formats: `.nvmrc`, `.node-version`, `.tool-versions`, `package.json` engines.node
- Handles version aliases: `lts`, `latest`, `stable`, `node`
- Automatic version installation when missing

### ⚡ **Performance & UX**

- **Smart caching** - Avoids redundant file reads and version switches
- **Debouncing** - Prevents rapid switching during quick navigation
- **Silent mode** - Suppress output messages
- **Visual indicators** - Display current Node.js version in prompt

### 🔧 **Multi-Manager Compatibility**

- **nvm** - Node Version Manager
- **fnm** - Fast Node Manager
- **volta** - JavaScript toolchain manager
- **asdf** - Extendable version manager

### ⚙️ **Extensive Configuration**

- Toggle automatic installation
- Directory exclusion patterns
- Configurable debounce timing
- Manager preference selection
- Project-only activation mode

### 🔔 **Advanced Developer Tools**

- **Security features**: Version validation, CVE checking, policy enforcement
- **Smart recommendations**: Intelligent version suggestions and upgrade paths
- **Comprehensive diagnostics**: `nvm_doctor` for troubleshooting and health checks
- **Performance optimization**: XDG-compliant caching with TTL, async operations
- **Error recovery**: Graceful degradation and fallback mechanisms
- Desktop notifications for version switches
- Environment variable export (`NODE_VERSION`)
- Fish shell completions and detailed status reporting

## Quick Start

After installation, the plugin works automatically! Simply navigate to any directory with a Node.js version file:

```fish
# Create a project with specific Node version
echo "18.17.0" > .nvmrc
cd .  # Automatically switches to Node.js v18.17.0

# Works with package.json too
echo '{"engines": {"node": ">=16.0.0"}}' > package.json
cd .  # Switches to compatible Node.js version
```

## Configuration

Customize the plugin behavior with `nvm_auto_use_config`:

```fish
# View current settings
nvm_auto_use_config

# Enable silent mode
nvm_auto_use_config silent on

# Disable automatic installation
nvm_auto_use_config auto_install off

# Set preferred version manager
nvm_auto_use_config manager fnm

# Adjust debounce timing (milliseconds)
nvm_auto_use_config debounce 1000

# Exclude directories
nvm_auto_use_config exclude "build"
nvm_auto_use_config exclude "dist"

# Reset all settings
nvm_auto_use_config reset
```

## Supported File Formats

| File | Format | Example |
| ---- | ------ | ------- |
| `.nvmrc` | Plain version | `18.17.0` or `lts/hydrogen` |
| `.node-version` | Plain version | `18.17.0` |
| `.tool-versions` | Tool + version | `nodejs 18.17.0` |
| `package.json` | engines.node field | `"engines": {"node": ">=16.0.0"}` |

## Advanced Features

### Security & Validation

```fish
# Security audit and validation
nvm_security audit                    # Comprehensive security check
nvm_security check_version "18.17.0"  # Validate version format
nvm_security policy set min_version "16.0.0"  # Set minimum version policy
```

### Smart Recommendations

```fish
# Get intelligent recommendations
nvm_recommendations suggest_version new_project  # Project-specific suggestions
nvm_recommendations upgrade_path                 # Plan safe upgrades
nvm_recommendations security_update              # Security-focused updates
```

### Diagnostics & Troubleshooting

```fish
# Comprehensive system diagnostics
nvm_doctor check           # Full health check
nvm_doctor managers        # Check version manager status
nvm_doctor security        # Security audit
nvm_doctor fix all         # Auto-fix common issues
```

### Performance & Caching

```fish
# Cache management (XDG-compliant)
nvm_cache stats            # View cache statistics
nvm_cache clear            # Clear all cached data

# Async operations for better performance
nvm_async version_check "file"  # Non-blocking version checks
```

## Utility Functions

```fish
# Check current Node.js status
nvm_version_status

# Get version for prompt integration
nvm_version_prompt  # Returns: ⬢ 18.17.0

# Control silent mode
nvm_auto_use_silent on/off

# Detect available version managers
nvm_compat_detect
```

## Requirements

- Fish shell 3.0+
- At least one supported Node.js version manager:
    - [nvm](https://github.com/nvm-sh/nvm)
    - [fnm](https://github.com/Schniz/fnm)
    - [volta](https://volta.sh/)
    - [asdf](https://asdf-vm.com/) with nodejs plugin

## Development

### Contributing

This project uses comprehensive linting and code quality tools:

```bash
# Install development tools
make install-tools

# Run all linting checks
make lint

# Fix auto-fixable issues
make lint-fix

# Test plugin installation
make test
```

### Code Quality

- **Fish shell**: Automatic formatting with `fish_indent`
- **Markdown**: Style checking with `markdownlint`
- **JSON**: Syntax validation with `jsonlint`/`jq`
- **EditorConfig**: Compliance checking with `editorconfig-checker`

All tools are automatically installed if missing, following XDG directory standards.

### GitHub Actions

The project includes CI/CD workflows that automatically:

- Run all linting checks on push/PR
- Test plugin installation in clean environments
- Ensure code quality standards are maintained

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines.

## Uninstall

```fish
fisher remove ivuorinen/nvm-auto-use.fish
```

## License

MIT License. See [LICENSE](LICENSE) for details.

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fivuorinen%2Fnvm-auto-use.fish.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fivuorinen%2Fnvm-auto-use.fish?ref=badge_large)
