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

function test_config_reset
    echo "Testing _nvm_auto_use_config_reset..."

    set -g _nvm_auto_use_no_install 1
    set -g _nvm_auto_use_silent 1
    set -g _nvm_auto_use_debounce_ms 999
    set -g _nvm_auto_use_excluded_dirs foo
    set -g _nvm_auto_use_preferred_manager nvm

    _nvm_auto_use_config_reset

    test -z "$_nvm_auto_use_no_install"
    and test -z "$_nvm_auto_use_silent"
    and test -z "$_nvm_auto_use_debounce_ms"
    and test -z "$_nvm_auto_use_excluded_dirs"
    and test -z "$_nvm_auto_use_preferred_manager"
    and echo "✅ Config reset works"
    or echo "❌ Config reset failed"
end

function main
    test_config_show
    test_config_auto_install
    test_config_silent
    test_config_debounce
    test_config_exclude_include
    test_config_manager
    test_config_reset
end

main
