function nvm_cache -d "XDG-compliant cache management with TTL"
    set -l action $argv[1]
    set -l key $argv[2]
    set -l value $argv[3]
    set -l ttl $argv[4]

    switch $action
        case get
            _nvm_cache_get "$key" "$ttl"
        case set
            _nvm_cache_set "$key" "$value"
        case delete
            _nvm_cache_delete "$key"
        case clear
            _nvm_cache_clear
        case stats
            _nvm_cache_stats
        case '*'
            echo "Usage: nvm_cache [get|set|delete|clear|stats] <key> [value] [ttl]"
            return 1
    end
end

function _nvm_cache_dir -d "Get XDG cache directory for nvm-auto-use"
    if set -q XDG_CACHE_HOME
        echo "$XDG_CACHE_HOME/nvm-auto-use"
    else
        echo "$HOME/.cache/nvm-auto-use"
    end
end

function _nvm_cache_get -d "Get cache value by key, respecting TTL"
    set -l key $argv[1]
    set -l ttl $argv[2]
    set -l cache_dir (_nvm_cache_dir)
    set -l cache_file "$cache_dir/$key"

    if not test -f "$cache_file"
        return 1
    end

    # Check TTL
    set -l cache_time (stat -c %Y "$cache_file" 2>/dev/null; or stat -f %m "$cache_file" 2>/dev/null)
    set -l current_time (date +%s)
    set -l default_ttl 300 # 5 minutes default

    if test -n "$ttl"
        set default_ttl $ttl
    end

    if test (math "$current_time - $cache_time") -gt $default_ttl
        rm "$cache_file" 2>/dev/null
        return 1
    end

    cat "$cache_file"
    return 0
end

function _nvm_cache_set -d "Set cache value by key"
    set -l key $argv[1]
    set -l value $argv[2]
    set -l cache_dir (_nvm_cache_dir)
    set -l cache_file "$cache_dir/$key"

    if test -z "$value"
        return 1
    end

    mkdir -p "$cache_dir" 2>/dev/null
    echo "$value" >"$cache_file" 2>/dev/null
    return $status
end

function _nvm_cache_delete -d "Delete cache value by key"
    set -l key $argv[1]
    set -l cache_dir (_nvm_cache_dir)
    set -l cache_file "$cache_dir/$key"
    rm "$cache_file" 2>/dev/null
    return 0
end

function _nvm_cache_clear -d "Clear all cache files"
    set -l cache_dir (_nvm_cache_dir)
    rm -rf "$cache_dir" 2>/dev/null
    return 0
end

function _nvm_cache_stats -d "Show cache statistics"
    set -l cache_dir (_nvm_cache_dir)
    if test -d "$cache_dir"
        echo "Cache directory: $cache_dir"
        echo "Cache files: "(find "$cache_dir" -type f 2>/dev/null | wc -l)
        echo "Cache size: "(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    else
        echo "No cache directory found"
    end
    return 0
end

function _nvm_cache_key -d "Generate cache key from directory and file"
    set -l dir (pwd)
    set -l file_hash (echo "$argv[1]" | shasum | cut -d' ' -f1)
    echo "dir_$(echo "$dir" | shasum | cut -d' ' -f1)_$file_hash"
end

function _nvm_cache_manager_key -d "Generate cache key for manager availability"
    set -l manager $argv[1]
    echo "manager_$manager"
end
