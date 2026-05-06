function nvm_async -d "Async operations for non-blocking version management"
    set -l operation $argv[1]
    switch $operation
        case version_check
            _nvm_async_version_check $argv[2]
        case manager_check
            _nvm_async_manager_check $argv[2]
        case cleanup
            _nvm_async_cleanup
        case wait
            _nvm_async_wait $argv[2] $argv[3]
        case '*'
            echo "Usage: nvm_async [version_check|manager_check|cleanup|wait] [args...]"
            return 1
    end
end

function _nvm_async_version_check -d "Async version check operation"
    set -l version_file $argv[1]
    set -l cache_key (_nvm_cache_key "$version_file")

    # Try cache first
    if set -l cached_result (nvm_cache get "$cache_key" 60)
        echo "$cached_result"
        return 0
    end

    # Background job for version extraction. Pass values as positional
    # arguments so quotes/newlines/etc. in $version_file or $cache_key
    # cannot break the embedded script (and to close the door on
    # command-injection via untrusted file paths).
    fish -c '
        set -l version_file $argv[1]
        set -l cache_key $argv[2]
        set -l result (nvm_extract_version "$version_file" 2>/dev/null)
        if test -n "$result"
            nvm_cache set "$cache_key" "$result"
            echo "$result"
        end
    ' -- "$version_file" "$cache_key" &

    # Return PID of the background job
    echo $last_pid
end

function _nvm_async_manager_check -d "Async manager availability check"
    set -l manager $argv[1]

    # Validate manager against the allow-list before any further work — a
    # caller-supplied value with quotes/whitespace must not be embedded in
    # a `fish -c` script.
    if not contains -- "$manager" nvm fnm volta asdf
        return 1
    end

    set -l cache_key (_nvm_cache_manager_key "$manager")

    # Try cache first (longer TTL for manager availability)
    if set -l cached_result (nvm_cache get "$cache_key" 3600)
        echo "$cached_result"
        return 0
    end

    # Background check, passing values positionally rather than interpolating
    fish -c '
        set -l manager $argv[1]
        set -l cache_key $argv[2]
        if command -q $manager
            nvm_cache set "$cache_key" available
            echo available
        else
            nvm_cache set "$cache_key" unavailable
            echo unavailable
        end
    ' -- "$manager" "$cache_key" &

    echo $last_pid
end

function _nvm_async_cleanup -d "Clean up completed background jobs"
    for job in (jobs -p)
        if not kill -0 $job 2>/dev/null
            wait $job 2>/dev/null
        end
    end
end

function _nvm_async_wait -d "Wait for async job with timeout"
    set -l job_id $argv[1]
    set -l timeout $argv[2]

    if test -z "$timeout"
        set timeout 2
    end

    # Wait for job with timeout
    set -l count 0
    while test $count -lt (math "$timeout * 10")
        if not jobs -p | grep -q "^$job_id\$"
            return 0
        end
        sleep 0.1
        set count (math "$count + 1")
    end

    # Timeout reached, kill job
    kill -9 $job_id 2>/dev/null
    return 1
end

function _nvm_async_safe_read -d "Safely read async operation result"
    set -l cache_key $argv[1]
    set -l fallback $argv[2]

    set -l result (nvm_cache get "$cache_key")
    if test -n "$result"
        echo "$result"
    else if test -n "$fallback"
        echo "$fallback"
    end
end
