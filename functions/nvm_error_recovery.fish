function nvm_error_recovery -d "Error recovery and graceful degradation"
    set -l operation $argv[1]
    set -l error_context $argv[2]

    switch $operation
        case manager_failure
            set -l manager $argv[2]
            set -l target_version $argv[3]

            echo "⚠️  $manager failed to switch to version $target_version" >&2

            # Try fallback managers
            set -l fallback_managers (nvm_compat_detect | string split ' ')
            for fallback in $fallback_managers
                if test "$fallback" != "$manager"
                    echo "🔄 Trying fallback manager: $fallback" >&2
                    if _nvm_error_recovery_try_manager "$fallback" "$target_version"
                        echo "✅ Successfully switched using $fallback" >&2
                        return 0
                    end
                end
            end

            echo "❌ All managers failed. Staying on current version." >&2
            return 1

        case version_not_found
            set -l manager $argv[2]
            set -l requested_version $argv[3]

            echo "⚠️  Version $requested_version not found" >&2

            # Try to find similar versions
            set -l suggestions (_nvm_error_recovery_suggest_versions "$manager" "$requested_version")
            if test -n "$suggestions"
                echo "💡 Available similar versions: $suggestions" >&2

                # Auto-select best match if auto_install is disabled
                if set -q _nvm_auto_use_no_install
                    set -l best_match (echo "$suggestions" | string split ' ' | head -n 1)
                    echo "🔄 Trying closest match: $best_match" >&2
                    if _nvm_error_recovery_try_manager "$manager" "$best_match"
                        return 0
                    end
                end
            end

            return 1

        case network_failure
            echo "⚠️  Network failure during version operation" >&2

            # Check if we have a cached version list
            set -l cache_key "versions_$(echo $argv[2] | shasum | cut -d' ' -f1)"
            if set -l cached_versions (nvm_cache get "$cache_key" 86400) # 24 hour TTL
                echo "📦 Using cached version information" >&2
                echo "$cached_versions"
                return 0
            end

            echo "❌ No cached version information available" >&2
            return 1

        case permission_denied
            set -l operation_type $argv[2]
            echo "⚠️  Permission denied for $operation_type" >&2

            switch $operation_type
                case install
                    echo "💡 Try running with appropriate permissions or check manager configuration" >&2
                case switch
                    echo "💡 Check if the version is already installed or try with sudo" >&2
            end

            return 1

        case timeout
            set -l operation_type $argv[2]
            set -l timeout_duration $argv[3]

            echo "⏱️  Operation '$operation_type' timed out after $timeout_duration seconds" >&2
            echo "💡 Consider checking network connection or increasing timeout" >&2

            # Kill any hanging processes
            nvm_async cleanup
            return 1

        case corruption
            set -l file_path $argv[2]
            echo "⚠️  Corrupted file detected: $file_path" >&2

            # Try to recover from backup or regenerate
            if test -f "$file_path.backup"
                echo "🔄 Restoring from backup" >&2
                cp "$file_path.backup" "$file_path"
                return 0
            end

            echo "❌ No backup available, manual intervention required" >&2
            return 1

        case '*'
            echo "Unknown error recovery operation: $operation" >&2
            return 1
    end
end

function _nvm_error_recovery_try_manager -d "Try using a specific manager"
    set -l manager $argv[1]
    set -l version $argv[2]

    if not command -q "$manager"
        return 1
    end

    switch $manager
        case nvm
            nvm use "$version" 2>/dev/null
        case fnm
            fnm use "$version" 2>/dev/null
        case volta
            volta pin "node@$version" 2>/dev/null
        case asdf
            asdf local nodejs "$version" 2>/dev/null
        case '*'
            return 1
    end
end

function _nvm_error_recovery_suggest_versions -d "Suggest similar available versions"
    set -l manager $argv[1]
    set -l requested $argv[2]

    # Extract major version for suggestions
    set -l major (echo "$requested" | string replace -r '^v?([0-9]+).*' '$1')

    # Try to get available versions (with error handling)
    set -l available_versions
    switch $manager
        case nvm
            set available_versions (nvm list-remote 2>/dev/null | grep "^v$major\." | head -n 5)
        case fnm
            set available_versions (fnm list-remote 2>/dev/null | grep "^v$major\." | head -n 5)
        case asdf
            set available_versions (asdf list-all nodejs 2>/dev/null | grep "^$major\." | head -n 5)
    end

    echo "$available_versions" | string join ' '
end

function _nvm_error_recovery_log -d "Log error for debugging"
    set -l error_type $argv[1]
    set -l details $argv[2]

    # Log to XDG cache directory
    set -l log_dir
    if set -q XDG_CACHE_HOME
        set log_dir "$XDG_CACHE_HOME/nvm-auto-use"
    else
        set log_dir "$HOME/.cache/nvm-auto-use"
    end

    mkdir -p "$log_dir" 2>/dev/null
    set -l log_file "$log_dir/error.log"

    set -l timestamp (date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $error_type: $details" >>"$log_file"
end
