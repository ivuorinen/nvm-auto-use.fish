function nvm_auto_use --on-variable PWD
    # Select the Node.js version manager
    set -l manager (_nvm_auto_use_select_manager)
    if test -z "$manager"
        return
    end

    # Debounce rapid directory changes
    if _nvm_auto_use_should_debounce
        return
    end

    # Check for excluded directories
    if _nvm_auto_use_is_excluded_dir
        return
    end

    # Project-only mode: only activate in Node.js projects
    if set -q _nvm_auto_use_project_only
        if not nvm_project_detect
            return
        end
    end

    # Export NODE_VERSION environment variable if available
    if command -q node
        set -gx NODE_VERSION (node -v 2>/dev/null | string replace 'v' '')
    end

    # Find version file and its mtime
    set -l nvmrc_file (nvm_find_nvmrc)
    set -l nvmrc_mtime (_nvm_auto_use_get_mtime "$nvmrc_file")

    # Skip if cache is valid
    if _nvm_auto_use_is_cache_valid "$nvmrc_file" "$nvmrc_mtime"
        return
    end

    if test -n "$nvmrc_file"
        _nvm_auto_use_switch_version "$manager" "$nvmrc_file" "$nvmrc_mtime"
    else
        _nvm_auto_use_clear_cache
    end
end

function _nvm_auto_use_select_manager
    set -l available_managers (nvm_compat_detect 2>/dev/null)
    if test -z "$available_managers"
        return
    end
    if test -n "$_nvm_auto_use_preferred_manager"
        if contains "$_nvm_auto_use_preferred_manager" $available_managers
            echo "$_nvm_auto_use_preferred_manager"
            return
        end
    end
    echo $available_managers[1]
end

function _nvm_auto_use_should_debounce
    set -l debounce_ms (_nvm_auto_use_get_debounce)
    set -l current_time (date +%s%3N 2>/dev/null; or math "(date +%s) * 1000")
    if test -n "$_nvm_auto_use_last_change"
        set -l time_diff (math "$current_time - $_nvm_auto_use_last_change")
        if test $time_diff -lt $debounce_ms
            return 0
        end
    end
    set -g _nvm_auto_use_last_change $current_time
    return 1
end

function _nvm_auto_use_is_excluded_dir
    set -l current_dir (pwd)
    set -l patterns $_nvm_auto_use_excluded_dirs node_modules .git
    for pattern in $patterns
        if string match -q "*/$pattern" "$current_dir"; or string match -q "*/$pattern/*" "$current_dir"
            return 0
        end
    end
    return 1
end

function _nvm_auto_use_get_mtime
    set -l file $argv[1]
    if test -n "$file"
        stat -c %Y "$file" 2>/dev/null; or stat -f %m "$file" 2>/dev/null
    end
end

function _nvm_auto_use_is_cache_valid
    set -l file $argv[1]
    set -l mtime $argv[2]
    if test "$file" = "$_nvm_auto_use_cached_file"; and test "$mtime" = "$_nvm_auto_use_cached_mtime"
        return 0
    end
    return 1
end

function _nvm_auto_use_switch_version
    set -l manager $argv[1]
    set -l nvmrc_file $argv[2]
    set -l nvmrc_mtime $argv[3]
    set -l node_version (nvm_extract_version "$nvmrc_file")
    set -g _nvm_auto_use_cached_file "$nvmrc_file"
    set -g _nvm_auto_use_cached_mtime "$nvmrc_mtime"
    if not string match -qr '^v?[0-9]+(\..*)?$' "$node_version"
        if not set -q _nvm_auto_use_silent
            echo "Invalid Node.js version format in $nvmrc_file: $node_version" >&2
        end
        return 1
    end
    set node_version (string replace -r '^v' '' "$node_version")
    set -g _nvm_auto_use_cached_version "$node_version"
    set -l current_version
    if command -q node
        set current_version (node -v 2>/dev/null | sed 's/v//')
    end
    if test "$node_version" != "$current_version"
        if not set -q _nvm_auto_use_silent
            echo "Switching to Node.js v$node_version"
            nvm_notify "Switched to Node.js v$node_version"
        end
        if not nvm_compat_use $manager $node_version 2>/dev/null
            if set -q _nvm_auto_use_no_install
                if not set -q _nvm_auto_use_silent
                    echo "Node.js version $node_version not found (auto-install disabled)" >&2
                end
                return 1
            end
            if not set -q _nvm_auto_use_silent
                echo "Node.js version $node_version not found, installing..."
            end
            if nvm_compat_install $manager $node_version >/dev/null 2>&1
                nvm_compat_use $manager $node_version >/dev/null 2>&1
                if not set -q _nvm_auto_use_silent
                    echo "Installed and switched to Node.js v$node_version"
                end
            else
                if not set -q _nvm_auto_use_silent
                    echo "Failed to install Node.js version $node_version" >&2
                end
                return 1
            end
        end
        set -g _nvm_auto_use_cached_version "$node_version"
        set -gx NODE_VERSION "$node_version"
    end
end

function _nvm_auto_use_clear_cache
    set -e _nvm_auto_use_cached_file
    set -e _nvm_auto_use_cached_version
    set -e _nvm_auto_use_cached_mtime
end
