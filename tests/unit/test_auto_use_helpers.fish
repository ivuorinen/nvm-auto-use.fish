#!/usr/bin/env fish
# Unit tests for nvm_auto_use helper functions

source (path normalize (dirname (status --current-filename))/../test_runner.fish)

function test_select_manager
    echo "Testing _nvm_auto_use_select_manager..."
    set -l failed 0

    # Mock nvm_compat_detect to return a list
    function nvm_compat_detect
        echo "nvm fnm volta"
    end

    set -eg _nvm_auto_use_preferred_manager
    set -l manager (_nvm_auto_use_select_manager)
    assert_equals "$manager" nvm "Default manager selection returns first available"
    or set failed 1

    set -g _nvm_auto_use_preferred_manager volta
    set manager (_nvm_auto_use_select_manager)
    assert_equals "$manager" volta "Preferred manager selection works"
    or set failed 1

    set -eg _nvm_auto_use_preferred_manager
    # Note: leaving the nvm_compat_detect mock in place. `functions -e` here
    # would prevent fish from autoloading the real implementation later
    # (subsequent tests' cd hooks would otherwise hit "Unknown command").

    return $failed
end

function test_should_debounce
    echo "Testing _nvm_auto_use_should_debounce..."

    set -eg _nvm_auto_use_last_change
    set -g _nvm_auto_use_debounce_ms 1000

    # These helpers communicate via $status, not stdout. Capturing the
    # (always-empty) output and asserting equality with "" silently passes
    # even if the logic is wrong — so check the exit status directly.

    # First call: no prior change recorded → not debounced (return 1).
    _nvm_auto_use_should_debounce
    if test $status -ne 0
        echo "✅ First call not debounced"
    else
        echo "❌ First call should not have been debounced"
        return 1
    end

    # Second call within debounce window → debounced (return 0).
    _nvm_auto_use_should_debounce
    if test $status -eq 0
        echo "✅ Second call debounced"
    else
        echo "❌ Second call should have been debounced"
        return 1
    end

    set -eg _nvm_auto_use_last_change
    set -eg _nvm_auto_use_debounce_ms
end

function test_is_excluded_dir
    echo "Testing _nvm_auto_use_is_excluded_dir..."

    set -g _nvm_auto_use_excluded_dirs testdir
    set -l orig_pwd (pwd)
    mkdir -p "$TEST_DIR/testdir"
    cd "$TEST_DIR/testdir"

    _nvm_auto_use_is_excluded_dir
    if test $status -eq 0
        echo "✅ Excluded directory detected"
    else
        echo "❌ Excluded directory not detected"
        cd "$orig_pwd"
        set -eg _nvm_auto_use_excluded_dirs
        return 1
    end

    cd "$orig_pwd"
    set -eg _nvm_auto_use_excluded_dirs
end

function test_get_mtime
    echo "Testing _nvm_auto_use_get_mtime..."

    echo test >testfile
    set -l mtime (_nvm_auto_use_get_mtime "testfile")
    rm -f testfile
    if test -n "$mtime"
        echo "✅ mtime returned: $mtime"
    else
        echo "❌ mtime not returned"
        return 1
    end
end

function test_is_cache_valid
    echo "Testing _nvm_auto_use_is_cache_valid..."

    set -g _nvm_auto_use_cached_file foo
    set -g _nvm_auto_use_cached_mtime 123

    _nvm_auto_use_is_cache_valid foo 123
    if test $status -eq 0
        echo "✅ Cache valid for matching file/mtime"
    else
        echo "❌ Cache should be valid for matching file/mtime"
        set -eg _nvm_auto_use_cached_file
        set -eg _nvm_auto_use_cached_mtime
        return 1
    end

    _nvm_auto_use_is_cache_valid bar 123
    if test $status -ne 0
        echo "✅ Cache invalid for different file"
    else
        echo "❌ Cache should be invalid for different file"
        set -eg _nvm_auto_use_cached_file
        set -eg _nvm_auto_use_cached_mtime
        return 1
    end

    # Empty file path must not short-circuit to "valid"
    _nvm_auto_use_is_cache_valid "" ""
    if test $status -ne 0
        echo "✅ Cache invalid for empty file"
    else
        echo "❌ Cache must not be valid when no file is detected"
        set -eg _nvm_auto_use_cached_file
        set -eg _nvm_auto_use_cached_mtime
        return 1
    end

    set -eg _nvm_auto_use_cached_file
    set -eg _nvm_auto_use_cached_mtime
end

function test_clear_cache
    echo "Testing _nvm_auto_use_clear_cache..."
    set -l failed 0

    set -g _nvm_auto_use_cached_file foo
    set -g _nvm_auto_use_cached_version bar
    set -g _nvm_auto_use_cached_mtime baz
    _nvm_auto_use_clear_cache
    if not set -q _nvm_auto_use_cached_file
        echo "✅ Cached file cleared"
    else
        echo "❌ Cached file not cleared"
        set failed 1
    end
    if not set -q _nvm_auto_use_cached_version
        echo "✅ Cached version cleared"
    else
        echo "❌ Cached version not cleared"
        set failed 1
    end
    if not set -q _nvm_auto_use_cached_mtime
        echo "✅ Cached mtime cleared"
    else
        echo "❌ Cached mtime not cleared"
        set failed 1
    end
    return $failed
end

function main
    setup_test_env

    set -l failed 0

    test_select_manager; or set failed (math "$failed + 1")
    test_should_debounce; or set failed (math "$failed + 1")
    test_is_excluded_dir; or set failed (math "$failed + 1")
    test_get_mtime; or set failed (math "$failed + 1")
    test_is_cache_valid; or set failed (math "$failed + 1")
    test_clear_cache; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "🎉 All nvm_auto_use helper tests passed!"
        return 0
    else
        echo "💥 $failed helper test(s) failed"
        return 1
    end
end

main
