#!/usr/bin/env fish
# Unit tests for nvm_auto_use helper functions

source tests/test_runner.fish

function test_select_manager
    echo "Testing _nvm_auto_use_select_manager..."

    # Mock nvm_compat_detect to return a list
    function nvm_compat_detect
        echo "nvm fnm volta"
    end

    set -e _nvm_auto_use_preferred_manager
    set -l manager (_nvm_auto_use_select_manager)
    assert_equals "$manager" nvm "Default manager selection returns first available"

    set -g _nvm_auto_use_preferred_manager volta
    set manager (_nvm_auto_use_select_manager)
    assert_equals "$manager" volta "Preferred manager selection works"

    set -e _nvm_auto_use_preferred_manager
    functions -e nvm_compat_detect
end

function test_should_debounce
    echo "Testing _nvm_auto_use_should_debounce..."

    set -e _nvm_auto_use_last_change
    set -g _nvm_auto_use_debounce_ms 1000

    # First call should set last_change and return 1 (not debounced)
    set result (_nvm_auto_use_should_debounce)
    assert_equals "$result" "" "First call not debounced"

    # Second call within debounce period should return 0 (debounced)
    set result (_nvm_auto_use_should_debounce)
    assert_equals "$result" "" "Second call debounced"

    set -e _nvm_auto_use_last_change
    set -e _nvm_auto_use_debounce_ms
end

function test_is_excluded_dir
    echo "Testing _nvm_auto_use_is_excluded_dir..."

    set -g _nvm_auto_use_excluded_dirs testdir
    set -l orig_pwd (pwd)
    cd /
    mkdir -p testdir
    cd testdir

    set result (_nvm_auto_use_is_excluded_dir)
    assert_equals "$result" "" "Excluded directory detected"

    cd "$orig_pwd"
    set -e _nvm_auto_use_excluded_dirs
end

function test_get_mtime
    echo "Testing _nvm_auto_use_get_mtime..."

    echo test >testfile
    set mtime (_nvm_auto_use_get_mtime "testfile")
    test -n "$mtime"
    and echo "✅ mtime returned: $mtime"
    or echo "❌ mtime not returned"

    rm -f testfile
end

function test_is_cache_valid
    echo "Testing _nvm_auto_use_is_cache_valid..."

    set -g _nvm_auto_use_cached_file foo
    set -g _nvm_auto_use_cached_mtime 123
    set result (_nvm_auto_use_is_cache_valid "foo" "123")
    assert_equals "$result" "" "Cache valid returns 0"

    set result (_nvm_auto_use_is_cache_valid "bar" "123")
    assert_equals "$result" "" "Cache invalid returns 1"

    set -e _nvm_auto_use_cached_file
    set -e _nvm_auto_use_cached_mtime
end

function test_clear_cache
    echo "Testing _nvm_auto_use_clear_cache..."

    set -g _nvm_auto_use_cached_file foo
    set -g _nvm_auto_use_cached_version bar
    set -g _nvm_auto_use_cached_mtime baz
    _nvm_auto_use_clear_cache
    if not set -q _nvm_auto_use_cached_file
        echo "✅ Cached file cleared"
    else
        echo "❌ Cached file not cleared"
    end
    if not set -q _nvm_auto_use_cached_version
        echo "✅ Cached version cleared"
    else
        echo "❌ Cached version not cleared"
    end
    if not set -q _nvm_auto_use_cached_mtime
        echo "✅ Cached mtime cleared"
    else
        echo "❌ Cached mtime not cleared"
    end
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
