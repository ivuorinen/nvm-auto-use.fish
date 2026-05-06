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

### 🔔 **Developer Tools**

- Desktop notifications for version switches
- Environment variable export (`NODE_VERSION`)
- Fish shell completions
- Detailed status reporting

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
|------|--------|---------|
| `.nvmrc` | Plain version | `18.17.0` or `lts/hydrogen` |
| `.node-version` | Plain version | `18.17.0` |
| `.tool-versions` | Tool + version | `nodejs 18.17.0` |
| `package.json` | engines.node field | `"engines": {"node": ">=16.0.0"}` |

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

## Uninstall

```fish
fisher remove ivuorinen/nvm-auto-use.fish
```

## License

MIT License. See [LICENSE](LICENSE) for details.


[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fivuorinen%2Fnvm-auto-use.fish.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fivuorinen%2Fnvm-auto-use.fish?ref=badge_large)