#!/usr/bin/env fish
# Unit tests for nvm_auto_use_config helper functions

source tests/test_runner.fish

function test_config_show
    echo "Testing _nvm_auto_use_config_show..."

    # Should print config summary (no error)
    if _nvm_auto_use_config_show
        echo "✅ Config show prints summary"
    else
        echo "❌ Config show failed"
        return 1
    end
end

function test_config_auto_install
    echo "Testing _nvm_auto_use_config_auto_install..."
    set -l failed 0

    _nvm_auto_use_config_auto_install on
    if test -z "$_nvm_auto_use_no_install"
        echo "✅ Auto-install enabled"
    else
        echo "❌ Auto-install enable failed"
        set failed 1
    end

    _nvm_auto_use_config_auto_install off
    if test -n "$_nvm_auto_use_no_install"
        echo "✅ Auto-install disabled"
    else
        echo "❌ Auto-install disable failed"
        set failed 1
    end

    return $failed
end

function test_config_silent
    echo "Testing _nvm_auto_use_config_silent..."
    set -l failed 0

    _nvm_auto_use_config_silent on
    if test -n "$_nvm_auto_use_silent"
        echo "✅ Silent mode enabled"
    else
        echo "❌ Silent mode enable failed"
        set failed 1
    end

    _nvm_auto_use_config_silent off
    if test -z "$_nvm_auto_use_silent"
        echo "✅ Silent mode disabled"
    else
        echo "❌ Silent mode disable failed"
        set failed 1
    end

    return $failed
end

function test_config_debounce
    echo "Testing _nvm_auto_use_config_debounce..."

    _nvm_auto_use_config_debounce 1234
    assert_equals "$_nvm_auto_use_debounce_ms" 1234 "Debounce set correctly"
    or return 1

    _nvm_auto_use_config_debounce ""
    assert_equals "$_nvm_auto_use_debounce_ms" 1234 "Debounce unchanged on invalid input"
    or return 1
end

function test_config_exclude_include
    echo "Testing _nvm_auto_use_config_exclude and _nvm_auto_use_config_include..."

    set -eg _nvm_auto_use_excluded_dirs
    _nvm_auto_use_config_exclude testdir
    assert_contains "$_nvm_auto_use_excluded_dirs" testdir "Exclude added"
    or return 1

    _nvm_auto_use_config_include testdir
    assert_not_contains "$_nvm_auto_use_excluded_dirs" testdir "Exclude removed"
    or return 1
end

function test_config_manager
    echo "Testing _nvm_auto_use_config_manager..."
    set -l failed 0

    _nvm_auto_use_config_manager nvm
    assert_equals "$_nvm_auto_use_preferred_manager" nvm "Manager set to nvm"
    or set failed 1

    _nvm_auto_use_config_manager ""
    if test -z "$_nvm_auto_use_preferred_manager"
        echo "✅ Manager reset to auto-detect"
    else
        echo "❌ Manager reset failed"
        set failed 1
    end

    _nvm_auto_use_config_manager invalid
    assert_not_equals "$_nvm_auto_use_preferred_manager" invalid "Invalid manager not set"
    or set failed 1

    return $failed
end

function test_config_project_only
    echo "Testing _nvm_auto_use_config_project_only..."
    set -l failed 0

    _nvm_auto_use_config_project_only on
    if test -n "$_nvm_auto_use_project_only"
        echo "✅ Project-only mode enabled"
    else
        echo "❌ Project-only enable failed"
        set failed 1
    end

    _nvm_auto_use_config_project_only off
    if test -z "$_nvm_auto_use_project_only"
        echo "✅ Project-only mode disabled"
    else
        echo "❌ Project-only disable failed"
        set failed 1
    end

    _nvm_auto_use_config_project_only invalid
    if test $status -ne 0
        echo "✅ Invalid value returns error"
    else
        echo "❌ Invalid value should have returned error"
        set failed 1
    end

    return $failed
end

function test_config_reset
    echo "Testing _nvm_auto_use_config_reset..."

    set -g _nvm_auto_use_no_install 1
    set -g _nvm_auto_use_silent 1
    set -g _nvm_auto_use_project_only 1
    set -g _nvm_auto_use_debounce_ms 999
    set -g _nvm_auto_use_excluded_dirs foo
    set -g _nvm_auto_use_preferred_manager nvm

    _nvm_auto_use_config_reset

    if test -z "$_nvm_auto_use_no_install"
        and test -z "$_nvm_auto_use_silent"
        and test -z "$_nvm_auto_use_project_only"
        and test -z "$_nvm_auto_use_debounce_ms"
        and test -z "$_nvm_auto_use_excluded_dirs"
        and test -z "$_nvm_auto_use_preferred_manager"
        echo "✅ Config reset works"
    else
        echo "❌ Config reset failed"
        return 1
    end
end

function main
    setup_test_env

    set -l failed 0

    test_config_show; or set failed (math "$failed + 1")
    test_config_auto_install; or set failed (math "$failed + 1")
    test_config_silent; or set failed (math "$failed + 1")
    test_config_project_only; or set failed (math "$failed + 1")
    test_config_debounce; or set failed (math "$failed + 1")
    test_config_exclude_include; or set failed (math "$failed + 1")
    test_config_manager; or set failed (math "$failed + 1")
    test_config_reset; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "All config helper tests passed!"
        return 0
    else
        echo "$failed config helper test(s) failed"
        return 1
    end
end

main
