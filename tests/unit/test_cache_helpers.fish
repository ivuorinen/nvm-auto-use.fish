#!/usr/bin/env fish
# Unit tests for nvm_cache helper functions

source tests/test_runner.fish

function test_nvm_cache_get_set_delete
    echo "Testing _nvm_cache_set, _nvm_cache_get, and _nvm_cache_delete..."

    set -l key test_key
    set -l value test_value

    # Set cache value
    _nvm_cache_set $key $value
    set -l result (_nvm_cache_get $key 300)
    assert_equals "$result" "$value" "Cache set and get returns correct value"

    # Delete cache value
    _nvm_cache_delete $key
    set -l result (_nvm_cache_get $key 300)
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Cache delete works"
    or echo "❌ Cache delete failed"

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

    # Clear cache
    _nvm_cache_clear
    set -l stats_after (_nvm_cache_stats)
    assert_contains "$stats_after" "Cache files: 0" "Cache clear removes all files"

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

    # Simulate expired cache by setting TTL to 0
    set -l result (_nvm_cache_get $key 0)
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Cache TTL expiration works"
    or echo "❌ Cache TTL expiration failed"

    _nvm_cache_delete $key

    return 0
end

function test_nvm_cache_dir
    echo "Testing _nvm_cache_dir returns a valid directory..."

    set -l dir (_nvm_cache_dir)
    test -n "$dir"
    and echo "✅ _nvm_cache_dir returns: $dir"
    or echo "❌ _nvm_cache_dir did not return a directory"

    return 0
end

function main
    set -l failed 0

    test_nvm_cache_get_set_delete; or set failed (math "$failed + 1")
    test_nvm_cache_clear_and_stats; or set failed (math "$failed + 1")
    test_nvm_cache_ttl; or set failed (math "$failed + 1")
    test_nvm_cache_dir; or set failed (math "$failed + 1")

    if test $failed -eq 0
        echo "🎉 All nvm_cache helper tests passed!"
        return 0
    else
        echo "💥 $failed nvm_cache helper test(s) failed"
        return 1
    end
end

main
