#!/usr/bin/env fish
# Unit tests for nvm_cache.fish

source (path normalize (dirname (status --current-filename))/../test_runner.fish)

function test_cache_basic_operations
    echo "Testing basic cache operations..."

    # Test set and get
    nvm_cache set test_key test_value
    set -l result (nvm_cache get "test_key")
    assert_equals "$result" test_value "Cache set and get works"
    or return 1

    # Test delete
    nvm_cache delete test_key
    nvm_cache get test_key >/dev/null
    if test $status -ne 0
        echo "✅ Cache delete works"
    else
        echo "❌ Cache delete failed"
        return 1
    end

    return 0
end

function test_cache_ttl
    echo "Testing cache TTL..."

    # Set with short TTL
    nvm_cache set ttl_key ttl_value

    # Should exist immediately
    set -l result (nvm_cache get "ttl_key" 10)
    assert_equals "$result" ttl_value "Cache value exists within TTL"
    or return 1

    # Mock expired cache by setting TTL to 0
    nvm_cache get ttl_key 0 >/dev/null
    if test $status -ne 0
        echo "✅ Cache TTL expiration works"
    else
        echo "❌ Cache TTL expiration failed"
        return 1
    end

    return 0
end

function test_cache_stats
    echo "Testing cache stats..."

    # Clear cache first
    nvm_cache clear

    # Add some items
    nvm_cache set stats_key1 value1
    nvm_cache set stats_key2 value2

    # Get stats
    set -l stats (nvm_cache stats)
    assert_contains "$stats" "Cache files: 2" "Cache stats shows correct file count"
    or return 1

    return 0
end

function test_cache_stats_with_broken_fd
    echo "Testing cache stats with a broken fd shim on PATH..."

    # A mise/asdf shim with no version selected satisfies `command -q fd` but
    # prints nothing and exits non-zero. Counting via fd then silently reported
    # zero files. Guard the file count against any reintroduction of fd.
    set -l shim_dir "$TEST_DIR/brokenbin"
    mkdir -p "$shim_dir"
    printf '#!/bin/sh\necho "mise ERROR No version is set for shim: fd" >&2\nexit 1\n' >"$shim_dir/fd"
    chmod +x "$shim_dir/fd"

    set -l saved_path $PATH
    set -gx PATH "$shim_dir" $PATH

    nvm_cache clear
    nvm_cache set broken_fd_key1 value1
    nvm_cache set broken_fd_key2 value2

    set -l stats (nvm_cache stats)

    set -gx PATH $saved_path

    assert_contains "$stats" "Cache files: 2" "Cache stats counts files without depending on fd"
    or return 1

    return 0
end

function test_cache_key_generation
    echo "Testing cache key generation..."

    # Test directory-based key
    set -l key1 (_nvm_cache_key "test_file.txt")
    set -l key2 (_nvm_cache_key "test_file.txt")
    assert_equals "$key1" "$key2" "Same file generates same cache key"
    or return 1

    # Test different files generate different keys
    set -l key3 (_nvm_cache_key "different_file.txt")
    assert_not_equals "$key1" "$key3" "Different files generate different cache keys"
    or return 1

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_cache_basic_operations; or set failed (math "$failed + 1")
    test_cache_ttl; or set failed (math "$failed + 1")
    test_cache_stats; or set failed (math "$failed + 1")
    test_cache_stats_with_broken_fd; or set failed (math "$failed + 1")
    test_cache_key_generation; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "🎉 All cache tests passed!"
        return 0
    else
        echo "💥 $failed cache test(s) failed"
        return 1
    end
end

main
