function nvm_doctor -d "Comprehensive diagnostic and debugging tool"
    set -l action $argv[1]

    switch $action
        case check
            _nvm_doctor_full_check
        case system
            _nvm_doctor_system_info
        case managers
            _nvm_doctor_check_managers
        case permissions
            _nvm_doctor_check_permissions
        case config
            _nvm_doctor_check_config
        case cache
            _nvm_doctor_check_cache
        case security
            _nvm_doctor_security_audit
        case performance
            _nvm_doctor_performance_check
        case fix
            _nvm_doctor_auto_fix $argv[2..-1]
        case '*'
            echo "Usage: nvm_doctor [check|system|managers|permissions|config|cache|security|performance|fix] [args...]"
            echo
            echo "Commands:"
            echo "  check        - Run comprehensive diagnostic check"
            echo "  system       - Show system information"
            echo "  managers     - Check version manager status"
            echo "  permissions  - Check file and directory permissions"
            echo "  config       - Validate configuration"
            echo "  cache        - Check cache status and health"
            echo "  security     - Run security audit"
            echo "  performance  - Analyze performance issues"
            echo "  fix          - Attempt to fix common issues"
            return 1
    end
end

function _nvm_doctor_full_check -d "Run comprehensive diagnostic check"
    echo "🩺 NVM Auto-Use Doctor - Comprehensive Check"
    echo "============================================="
    echo

    set -l issues 0

    # System check
    echo "🖥️  System Information"
    echo ---------------------
    _nvm_doctor_system_info
    echo

    # Manager check
    echo "🔧 Version Manager Status"
    echo -------------------------
    _nvm_doctor_check_managers
    set issues (math "$issues + $status")
    echo

    # Configuration check
    echo "⚙️  Configuration Status"
    echo ------------------------
    _nvm_doctor_check_config
    set issues (math "$issues + $status")
    echo

    # Permissions check
    echo "🔐 Permissions Check"
    echo -------------------
    _nvm_doctor_check_permissions
    set issues (math "$issues + $status")
    echo

    # Cache check
    echo "🗄️  Cache Status"
    echo ----------------
    _nvm_doctor_check_cache
    set issues (math "$issues + $status")
    echo

    # Security audit
    echo "🔒 Security Audit"
    echo -----------------
    _nvm_doctor_security_audit
    set issues (math "$issues + $status")
    echo

    # Performance check
    echo "⚡ Performance Analysis"
    echo ----------------------
    _nvm_doctor_performance_check
    set issues (math "$issues + $status")
    echo

    # Summary
    echo "📋 Diagnostic Summary"
    echo "====================="
    if test $issues -eq 0
        echo "✅ All checks passed! Your nvm-auto-use setup is healthy."
    else
        echo "⚠️  Found $issues issue(s) that may need attention."
        echo "💡 Run 'nvm_doctor fix' to attempt automatic fixes."
    end

    return $issues
end

function _nvm_doctor_system_info -d "Display system information"
    echo "OS: "(uname -s)" "(uname -r)
    echo "Architecture: "(uname -m)
    echo "Shell: $SHELL"
    echo "Fish version: "(fish --version)

    if command -q node
        echo "Node.js: "(node --version)
    else
        echo "Node.js: Not installed"
    end

    if command -q npm
        echo "npm: "(npm --version)
    else
        echo "npm: Not available"
    end

    echo "PATH entries: "(echo $PATH | string split ':' | wc -l)
    echo "Current directory: "(pwd)
end

function _nvm_doctor_check_managers -d "Check version manager availability and status"
    set -l issues 0
    set -l managers (nvm_compat_detect 2>/dev/null)

    if test -z "$managers"
        echo "❌ No Node.js version managers found"
        echo "   Install at least one: nvm, fnm, volta, or asdf"
        set issues (math "$issues + 1")
    else
        echo "✅ Found managers: $managers"

        # Check each manager's status
        for manager in (echo $managers | string split ' ')
            echo "   📋 $manager status:"
            switch $manager
                case nvm
                    if test -f "$HOME/.nvm/nvm.sh"
                        echo "      ✅ NVM script found"
                        if command -q nvm
                            echo "      ✅ NVM command available"
                        else
                            echo "      ⚠️  NVM not in PATH (normal for Fish)"
                        end
                    else
                        echo "      ❌ NVM installation not found"
                        set issues (math "$issues + 1")
                    end
                case fnm
                    if command -q fnm
                        echo "      ✅ FNM available: "(fnm --version)
                    else
                        echo "      ❌ FNM not found in PATH"
                        set issues (math "$issues + 1")
                    end
                case volta
                    if command -q volta
                        echo "      ✅ Volta available: "(volta --version)
                    else
                        echo "      ❌ Volta not found in PATH"
                        set issues (math "$issues + 1")
                    end
                case asdf
                    if command -q asdf
                        echo "      ✅ asdf available: "(asdf --version)
                        if asdf plugin list | grep -q nodejs
                            echo "      ✅ nodejs plugin installed"
                        else
                            echo "      ❌ nodejs plugin not installed"
                            set issues (math "$issues + 1")
                        end
                    else
                        echo "      ❌ asdf not found in PATH"
                        set issues (math "$issues + 1")
                    end
            end
        end
    end

    return $issues
end

function _nvm_doctor_check_permissions -d "Check file and directory permissions"
    set -l issues 0

    # Check Fish functions directory
    set -l functions_dir (dirname (status current-filename))
    if test -d "$functions_dir"
        echo "✅ Functions directory accessible: $functions_dir"

        # Check individual function files
        for func_file in "$functions_dir"/nvm_*.fish
            if test -r "$func_file"
                echo "   ✅ $(basename $func_file) readable"
            else
                echo "   ❌ $(basename $func_file) not readable"
                set issues (math "$issues + 1")
            end
        end
    else
        echo "❌ Functions directory not found"
        set issues (math "$issues + 1")
    end

    # Check cache directory permissions
    set -l cache_dir
    if set -q XDG_CACHE_HOME
        set cache_dir "$XDG_CACHE_HOME/nvm-auto-use"
    else
        set cache_dir "$HOME/.cache/nvm-auto-use"
    end

    if test -d "$cache_dir"
        if test -w "$cache_dir"
            echo "✅ Cache directory writable: $cache_dir"
        else
            echo "❌ Cache directory not writable: $cache_dir"
            set issues (math "$issues + 1")
        end
    else
        echo "ℹ️  Cache directory doesn't exist (will be created as needed)"
    end

    # Check current directory permissions for version files
    if test -r "."
        echo "✅ Current directory readable"

        for version_file in .nvmrc .node-version .tool-versions package.json
            if test -f "$version_file"
                if test -r "$version_file"
                    echo "   ✅ $version_file readable"
                else
                    echo "   ❌ $version_file not readable"
                    set issues (math "$issues + 1")
                end
            end
        end
    else
        echo "❌ Current directory not readable"
        set issues (math "$issues + 1")
    end

    return $issues
end

function _nvm_doctor_check_config -d "Validate configuration"
    set -l issues 0

    echo "Configuration variables:"

    # Check debounce setting
    set -l debounce (_nvm_auto_use_get_debounce 2>/dev/null)
    if test -n "$debounce"
        echo "   ✅ Debounce: ${debounce}ms"
    else
        echo "   ℹ️  Debounce: Default (500ms)"
    end

    # Check excluded directories
    set -l excluded (_nvm_auto_use_get_excluded_dirs 2>/dev/null)
    echo "   ✅ Excluded dirs: $excluded"

    # Check auto-install setting
    if set -q _nvm_auto_use_no_install
        echo "   ✅ Auto-install: Disabled"
    else
        echo "   ✅ Auto-install: Enabled"
    end

    # Check silent mode
    if set -q _nvm_auto_use_silent
        echo "   ✅ Silent mode: Enabled"
    else
        echo "   ✅ Silent mode: Disabled"
    end

    # Check preferred manager
    if set -q _nvm_auto_use_preferred_manager
        echo "   ✅ Preferred manager: $_nvm_auto_use_preferred_manager"
    else
        echo "   ✅ Preferred manager: Auto-detect"
    end

    # Validate security policies
    echo "Security policies:"
    nvm_security policy list 2>/dev/null || echo "   ℹ️  No security policies set"

    return $issues
end

function _nvm_doctor_check_cache -d "Check cache status and health"
    set -l issues 0

    # Get cache stats
    nvm_cache stats

    # Check for corrupted cache files
    set -l cache_dir
    if set -q XDG_CACHE_HOME
        set cache_dir "$XDG_CACHE_HOME/nvm-auto-use"
    else
        set cache_dir "$HOME/.cache/nvm-auto-use"
    end

    if test -d "$cache_dir"
        set -l cache_files (find "$cache_dir" -type f 2>/dev/null)

        for cache_file in $cache_files
            if test -s "$cache_file"
                echo "   ✅ $(basename $cache_file) valid"
            else
                echo "   ⚠️  $(basename $cache_file) empty (may be normal)"
            end
        end

        # Check for very old cache files
        set -l old_files (find "$cache_dir" -type f -mtime +7 2>/dev/null)
        if test -n "$old_files"
            echo "   ℹ️  Found "(echo "$old_files" | wc -l)" cache files older than 7 days"
        end
    else
        echo "   ℹ️  No cache directory found"
    end

    return $issues
end

function _nvm_doctor_security_audit -d "Run security audit"
    nvm_security audit
end

function _nvm_doctor_performance_check -d "Analyze performance issues"
    set -l issues 0

    echo "Performance analysis:"

    # Check for excessive cache files
    set -l cache_dir
    if set -q XDG_CACHE_HOME
        set cache_dir "$XDG_CACHE_HOME/nvm-auto-use"
    else
        set cache_dir "$HOME/.cache/nvm-auto-use"
    end

    if test -d "$cache_dir"
        set -l cache_count (find "$cache_dir" -type f 2>/dev/null | wc -l)
        if test $cache_count -gt 100
            echo "   ⚠️  Large number of cache files ($cache_count) - consider cleanup"
            set issues (math "$issues + 1")
        else
            echo "   ✅ Reasonable cache size ($cache_count files)"
        end
    end

    # Check for very long directory paths
    set -l current_path (pwd)
    set -l path_length (string length "$current_path")
    if test $path_length -gt 200
        echo "   ⚠️  Very long current path may slow operations: $path_length characters"
        set issues (math "$issues + 1")
    else
        echo "   ✅ Path length reasonable: $path_length characters"
    end

    # Check for deep directory nesting
    set -l depth (echo "$current_path" | string replace -a '/' '\n' | wc -l)
    if test $depth -gt 15
        echo "   ⚠️  Deep directory nesting may slow file searches: $depth levels"
        set issues (math "$issues + 1")
    else
        echo "   ✅ Directory depth reasonable: $depth levels"
    end

    return $issues
end

function _nvm_doctor_auto_fix -d "Attempt to fix common issues"
    set -l fix_type $argv[1]

    echo "🔧 Attempting automatic fixes..."

    switch $fix_type
        case cache
            echo "Cleaning up cache..."
            nvm_cache clear
            echo "✅ Cache cleared"

        case permissions
            echo "Fixing cache directory permissions..."
            set -l cache_dir
            if set -q XDG_CACHE_HOME
                set cache_dir "$XDG_CACHE_HOME/nvm-auto-use"
            else
                set cache_dir "$HOME/.cache/nvm-auto-use"
            end

            mkdir -p "$cache_dir" 2>/dev/null
            chmod 755 "$cache_dir" 2>/dev/null
            echo "✅ Cache directory permissions fixed"

        case config
            echo "Resetting configuration to defaults..."
            nvm_auto_use_config reset
            echo "✅ Configuration reset"

        case all
            echo "Running all available fixes..."
            _nvm_doctor_auto_fix cache
            _nvm_doctor_auto_fix permissions
            echo "✅ All fixes completed"

        case '*'
            echo "Available fix types:"
            echo "  cache       - Clear cache files"
            echo "  permissions - Fix directory permissions"
            echo "  config      - Reset configuration"
            echo "  all         - Run all fixes"
            return 1
    end
end
