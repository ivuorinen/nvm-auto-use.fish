function nvm_auto_use --on-variable PWD
    # Detect available Node.js version manager
    set -l available_managers (nvm_compat_detect 2>/dev/null | tail -n 1)
    if test -z "$available_managers"
        return
    end

    # Use preferred manager or first available
    set -l manager
    if test -n "$_nvm_auto_use_preferred_manager"
        if contains "$_nvm_auto_use_preferred_manager" $available_managers
            set manager "$_nvm_auto_use_preferred_manager"
        end
    end

    if test -z "$manager"
        set manager $available_managers[1]
    end

    # Check if project detection is enabled and we're in a Node.js project
    if set -q _nvm_auto_use_project_only
        if not nvm_project_detect
            return
        end
    end

    # Export NODE_VERSION environment variable
    if command -q node
        set -gx NODE_VERSION (node -v 2>/dev/null | string replace 'v' '')
    end

    # Check for excluded directories
    set -l current_dir (pwd)
    for pattern in $_nvm_auto_use_excluded_dirs node_modules .git
        if string match -q "*/$pattern" "$current_dir"; or string match -q "*/$pattern/*" "$current_dir"
            return
        end
    end

    # Debouncing: prevent rapid switching
    set -l debounce_ms (_nvm_auto_use_get_debounce)
    set -l current_time (date +%s%3N 2>/dev/null; or date +%s)
    if test -n "$_nvm_auto_use_last_change"
        set -l time_diff (math "$current_time - $_nvm_auto_use_last_change")
        if test $time_diff -lt $debounce_ms
            return
        end
    end
    set -g _nvm_auto_use_last_change $current_time

    set -l nvmrc_file (nvm_find_nvmrc)

    # Cache check: if same file and version, skip processing
    if test "$nvmrc_file" = "$_nvm_auto_use_cached_file"
        return
    end

    if test -n "$nvmrc_file"
        set -l node_version (nvm_extract_version "$nvmrc_file")

        # Cache the file path
        set -g _nvm_auto_use_cached_file "$nvmrc_file"

        # Validate node version format (basic semver or major version)
        if not string match -qr '^v?[0-9]+(\..*)?$' "$node_version"
            if not set -q _nvm_auto_use_silent
                echo "Invalid Node.js version format in $nvmrc_file: $node_version" >&2
            end
            return 1
        end

        # Remove 'v' prefix if present
        set node_version (string replace -r '^v' '' "$node_version")

        # Cache the version
        set -g _nvm_auto_use_cached_version "$node_version"

        # Check the current version
        set -l current_version
        if command -q node
            set current_version (node -v 2>/dev/null | sed 's/v//')
        end

        if test "$node_version" != "$current_version"
            if not set -q _nvm_auto_use_silent
                echo "Switching to Node.js v$node_version"
            end

            # Send notification if enabled
            if not set -q _nvm_auto_use_silent
                nvm_notify "Switched to Node.js v$node_version"
            end

            if not nvm_compat_use $manager $node_version 2>/dev/null
                # Check if auto-install is disabled
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

            # Update cached version after successful switch
            set -g _nvm_auto_use_cached_version "$node_version"

            # Update NODE_VERSION environment variable
            set -gx NODE_VERSION "$node_version"
        end
    else
        # Clear cache if no .nvmrc found
        set -e _nvm_auto_use_cached_file
        set -e _nvm_auto_use_cached_version
    end
end
