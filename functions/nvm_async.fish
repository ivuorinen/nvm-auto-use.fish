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

    # Background job for version extraction
    fish -c "
        set result (nvm_extract_version '$version_file' 2>/dev/null)
        if test -n \"\$result\"
            nvm_cache set '$cache_key' \"\$result\"
            echo \"\$result\"
        end
    " &

    # Return job ID for potential cleanup
    jobs -l | tail -n 1 | grep -o '[0-9]*'
end

function _nvm_async_manager_check -d "Async manager availability check"
    set -l manager $argv[1]
    set -l cache_key (_nvm_cache_manager_key "$manager")

    # Try cache first (longer TTL for manager availability)
    if set -l cached_result (nvm_cache get "$cache_key" 3600)
        echo "$cached_result"
        return 0
    end

    # Background check
    fish -c "
        if command -q '$manager'
            nvm_cache set '$cache_key' 'available'
            echo 'available'
        else
            nvm_cache set '$cache_key' 'unavailable'
            echo 'unavailable'
        end
    " &

    jobs -l | tail -n 1 | grep -o '[0-9]*'
end

function _nvm_async_cleanup -d "Clean up completed background jobs"
    for job in (jobs -p)
        if not kill -0 $job 2>/dev/null
            jobs -p | grep -v $job
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
