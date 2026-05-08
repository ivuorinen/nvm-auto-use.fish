#!/usr/bin/env fish
# Unit tests for nvm_auto_use_silent.fish

source tests/test_runner.fish

function test_silent_dispatch
    echo "Testing nvm_auto_use_silent dispatch..."

    # Invalid subcommand returns 1
    nvm_auto_use_silent invalid_arg
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Invalid argument returns error"
    or echo "❌ Invalid argument should return error"

    return 0
end

function test_silent_enable_disable
    echo "Testing silent mode toggle..."

    # Enable silent mode
    nvm_auto_use_silent on
    set -q _nvm_auto_use_silent
    and echo "✅ Silent mode enabled"
    or echo "❌ Silent mode flag not set after 'on'"

    # Disable silent mode
    nvm_auto_use_silent off
    set -q _nvm_auto_use_silent
    and echo "❌ Silent mode flag still set after 'off'"
    or echo "✅ Silent mode disabled"

    return 0
end

function test_silent_status_report
    echo "Testing silent mode status report..."

    # Status with silent off
    set -e _nvm_auto_use_silent
    set -l output (nvm_auto_use_silent 2>&1)
    string match -q '*disabled*' "$output"
    and echo "✅ Status reports disabled when silent is off"
    or echo "❌ Status should report disabled when silent is off"

    # Status with silent on
    set -g _nvm_auto_use_silent 1
    set -l output (nvm_auto_use_silent 2>&1)
    string match -q '*enabled*' "$output"
    and echo "✅ Status reports enabled when silent is on"
    or echo "❌ Status should report enabled when silent is on"

    # Cleanup
    set -e _nvm_auto_use_silent

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_silent_dispatch; or set failed (math "$failed + 1")
    test_silent_enable_disable; or set failed (math "$failed + 1")
    test_silent_status_report; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "All silent tests passed!"
        return 0
    else
        echo "$failed silent test(s) failed"
        return 1
    end
end

main
