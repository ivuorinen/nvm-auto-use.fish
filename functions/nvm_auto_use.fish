function nvm_auto_use -d "Auto-switch Node.js version on directory change" --on-variable PWD
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

    # Export NODE_VERSION from the currently active binary. This snapshot is
    # intentionally early — after a successful version switch at the end of
    # this function, NODE_VERSION is updated again. Any subshell launched
    # between here and the switch sees the pre-switch value.
    if command -q node
        set -gx NODE_VERSION (node -v 2>/dev/null | string replace -r '^v' '')
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

function _nvm_auto_use_select_manager -d "Return the manager to use (preferred or first available)"
    set -l available_managers (nvm_compat_detect 2>/dev/null | string split ' ')
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

function _nvm_auto_use_should_debounce -d "Return 0 if within debounce window, 1 otherwise"
    set -l debounce_ms (_nvm_auto_use_get_debounce)
    # GNU date supports %3N (millisecond precision); BSD/macOS date silently
    # outputs a literal "3N" suffix, so we must validate the result before
    # using it. Fall back to seconds * 1000 if the precise form looks bogus.
    set -l current_time (date +%s%3N 2>/dev/null)
    if not string match -qr '^\d+$' -- "$current_time"
        # Fallback: convert seconds to milliseconds. `math` does not accept
        # command substitution inside its expression, so resolve the value
        # to a variable first.
        set -l seconds (date +%s)
        set current_time (math "$seconds * 1000")
    end
    if test -n "$_nvm_auto_use_last_change"
        set -l time_diff (math "$current_time - $_nvm_auto_use_last_change")
        if test $time_diff -lt $debounce_ms
            return 0
        end
    end
    set -g _nvm_auto_use_last_change $current_time
    return 1
end

function _nvm_auto_use_is_excluded_dir -d "Return 0 if current directory matches an exclusion pattern"
    set -l current_dir (pwd)
    set -l patterns $_nvm_auto_use_excluded_dirs node_modules .git
    for pattern in $patterns
        if string match -q "*/$pattern" "$current_dir"; or string match -q "*/$pattern/*" "$current_dir"
            return 0
        end
    end
    return 1
end

function _nvm_auto_use_get_mtime -d "Return mtime of the version file (strips :format suffix)"
    # nvm_find_nvmrc returns values like "path/to/package.json:engines.node"
    # for non-plain formats; strip the ":format" suffix so stat sees a real path.
    set -l file (string split -m 1 ':' -- "$argv[1]")[1]
    if test -n "$file"
        stat -c %Y "$file" 2>/dev/null; or stat -f %m "$file" 2>/dev/null
    end
end

function _nvm_auto_use_is_cache_valid -d "Return 0 if in-memory cache matches given file and mtime"
    set -l file $argv[1]
    set -l mtime $argv[2]
    # Treat empty file as "no cache" — empty == empty must not short-circuit
    # the rest of nvm_auto_use (which needs to clear stale caches when
    # there's no version file in the new directory).
    if test -z "$file"
        return 1
    end
    if test "$file" = "$_nvm_auto_use_cached_file"; and test "$mtime" = "$_nvm_auto_use_cached_mtime"
        return 0
    end
    return 1
end

function _nvm_auto_use_switch_version -d "Validate version and invoke the selected manager to switch"
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
        set current_version (node -v 2>/dev/null | string replace -r '^v' '')
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

function _nvm_auto_use_clear_cache -d "Erase the in-memory file/mtime/version cache globals"
    set -eg _nvm_auto_use_cached_file
    set -eg _nvm_auto_use_cached_version
    set -eg _nvm_auto_use_cached_mtime
end
