#!/usr/bin/env fish
# Unit tests for nvm_auto_use_config helper functions

source tests/test_runner.fish

function test_config_show
    echo "Testing _nvm_auto_use_config_show..."

    # Should print config summary (no error)
    _nvm_auto_use_config_show
    and echo "✅ Config show prints summary"
    or echo "❌ Config show failed"
end

function test_config_auto_install
    echo "Testing _nvm_auto_use_config_auto_install..."

    _nvm_auto_use_config_auto_install on
    test -z "$_nvm_auto_use_no_install"
    and echo "✅ Auto-install enabled"
    or echo "❌ Auto-install enable failed"

    _nvm_auto_use_config_auto_install off
    test -n "$_nvm_auto_use_no_install"
    and echo "✅ Auto-install disabled"
    or echo "❌ Auto-install disable failed"
end

function test_config_silent
    echo "Testing _nvm_auto_use_config_silent..."

    _nvm_auto_use_config_silent on
    test -n "$_nvm_auto_use_silent"
    and echo "✅ Silent mode enabled"
    or echo "❌ Silent mode enable failed"

    _nvm_auto_use_config_silent off
    test -z "$_nvm_auto_use_silent"
    and echo "✅ Silent mode disabled"
    or echo "❌ Silent mode disable failed"
end

function test_config_debounce
    echo "Testing _nvm_auto_use_config_debounce..."

    _nvm_auto_use_config_debounce 1234
    assert_equals "$_nvm_auto_use_debounce_ms" 1234 "Debounce set correctly"

    _nvm_auto_use_config_debounce ""
    assert_equals "$_nvm_auto_use_debounce_ms" 1234 "Debounce unchanged on invalid input"
end

function test_config_exclude_include
    echo "Testing _nvm_auto_use_config_exclude and _nvm_auto_use_config_include..."

    set -e _nvm_auto_use_excluded_dirs
    _nvm_auto_use_config_exclude testdir
    assert_contains "$_nvm_auto_use_excluded_dirs" testdir "Exclude added"

    _nvm_auto_use_config_include testdir
    assert_not_equals "$_nvm_auto_use_excluded_dirs" testdir "Exclude removed"
end

function test_config_manager
    echo "Testing _nvm_auto_use_config_manager..."

    _nvm_auto_use_config_manager nvm
    assert_equals "$_nvm_auto_use_preferred_manager" nvm "Manager set to nvm"

    _nvm_auto_use_config_manager ""
    test -z "$_nvm_auto_use_preferred_manager"
    and echo "✅ Manager reset to auto-detect"
    or echo "❌ Manager reset failed"

    _nvm_auto_use_config_manager invalid
    assert_not_equals "$_nvm_auto_use_preferred_manager" invalid "Invalid manager not set"
end

function test_config_project_only
    echo "Testing _nvm_auto_use_config_project_only..."

    _nvm_auto_use_config_project_only on
    test -n "$_nvm_auto_use_project_only"
    and echo "✅ Project-only mode enabled"
    or echo "❌ Project-only enable failed"

    _nvm_auto_use_config_project_only off
    test -z "$_nvm_auto_use_project_only"
    and echo "✅ Project-only mode disabled"
    or echo "❌ Project-only disable failed"

    _nvm_auto_use_config_project_only invalid
    and echo "❌ Invalid value should have returned error"
    or echo "✅ Invalid value returns error"
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

    test -z "$_nvm_auto_use_no_install"
    and test -z "$_nvm_auto_use_silent"
    and test -z "$_nvm_auto_use_project_only"
    and test -z "$_nvm_auto_use_debounce_ms"
    and test -z "$_nvm_auto_use_excluded_dirs"
    and test -z "$_nvm_auto_use_preferred_manager"
    and echo "✅ Config reset works"
    or echo "❌ Config reset failed"
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
