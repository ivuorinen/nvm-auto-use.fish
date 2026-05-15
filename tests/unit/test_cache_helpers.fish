#!/usr/bin/env fish
# Unit tests for nvm_cache helper functions

source (path normalize (dirname (status --current-filename))/../test_runner.fish)

function test_nvm_cache_get_set_delete
    echo "Testing _nvm_cache_set, _nvm_cache_get, and _nvm_cache_delete..."

    set -l key test_key
    set -l value test_value

    # Set cache value
    _nvm_cache_set $key $value
    set -l result (_nvm_cache_get $key 300)
    assert_equals "$result" "$value" "Cache set and get returns correct value"
    or return 1

    # Delete cache value
    _nvm_cache_delete $key
    _nvm_cache_get $key 300 >/dev/null
    if test $status -ne 0
        echo "✅ Cache delete works"
    else
        echo "❌ Cache delete failed"
        return 1
    end

    return 0
end

function test_nvm_cache_clear_and_stats
    echo "Testing _nvm_cache_clear and _nvm_cache_stats..."

    # Set multiple cache values
    _nvm_cache_set key1 value1
    _nvm_cache_set key2 value2

    # Stats should show at least 2 files
    set -l stats (_nvm_cache_stats)
    assert_contains "$stats" "Cache files:" "Cache stats reports file count"
    or return 1

    # Clear cache
    _nvm_cache_clear
    set -l stats_after (_nvm_cache_stats)
    assert_contains "$stats_after" "No cache directory found" "Cache clear removes the cache directory"
    or return 1

    return 0
end

function test_nvm_cache_ttl
    echo "Testing _nvm_cache_get TTL expiration..."

    set -l key ttl_key
    set -l value ttl_value

    _nvm_cache_set $key $value

    # Should exist immediately
    set -l result (_nvm_cache_get $key 10)
    assert_equals "$result" "$value" "Cache value exists within TTL"
    or return 1

    # Simulate expired cache by setting TTL to 0
    _nvm_cache_get $key 0 >/dev/null
    if test $status -ne 0
        echo "✅ Cache TTL expiration works"
    else
        echo "❌ Cache TTL expiration failed"
        return 1
    end

    _nvm_cache_delete $key

    return 0
end

function test_nvm_cache_dir
    echo "Testing _nvm_cache_dir returns a valid directory..."

    set -l dir (_nvm_cache_dir)
    if test -n "$dir"
        echo "✅ _nvm_cache_dir returns: $dir"
        return 0
    else
        echo "❌ _nvm_cache_dir did not return a directory"
        return 1
    end
end

function main
    setup_test_env

    set -l failed 0

    test_nvm_cache_get_set_delete; or set failed (math "$failed + 1")
    test_nvm_cache_clear_and_stats; or set failed (math "$failed + 1")
    test_nvm_cache_ttl; or set failed (math "$failed + 1")
    test_nvm_cache_dir; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "🎉 All nvm_cache helper tests passed!"
        return 0
    else
        echo "💥 $failed nvm_cache helper test(s) failed"
        return 1
    end
end

main
