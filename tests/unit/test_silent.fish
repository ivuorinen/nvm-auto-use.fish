#!/usr/bin/env fish
# Unit tests for nvm_auto_use_silent.fish

source (path normalize (dirname (status --current-filename))/../test_runner.fish)

function test_silent_dispatch
    echo "Testing nvm_auto_use_silent dispatch..."

    # Invalid subcommand returns 1
    nvm_auto_use_silent invalid_arg
    if test $status -ne 0
        echo "✅ Invalid argument returns error"
    else
        echo "❌ Invalid argument should return error"
        return 1
    end
end

function test_silent_enable_disable
    echo "Testing silent mode toggle..."
    set -l failed 0

    # Enable silent mode
    nvm_auto_use_silent on
    if set -q _nvm_auto_use_silent
        echo "✅ Silent mode enabled"
    else
        echo "❌ Silent mode flag not set after 'on'"
        set failed 1
    end

    # Disable silent mode
    nvm_auto_use_silent off
    if not set -q _nvm_auto_use_silent
        echo "✅ Silent mode disabled"
    else
        echo "❌ Silent mode flag still set after 'off'"
        set failed 1
    end

    return $failed
end

function test_silent_status_report
    echo "Testing silent mode status report..."
    set -l failed 0

    # Status with silent off
    set -e _nvm_auto_use_silent
    set -l output (nvm_auto_use_silent 2>&1)
    if string match -q '*disabled*' "$output"
        echo "✅ Status reports disabled when silent is off"
    else
        echo "❌ Status should report disabled when silent is off"
        set failed 1
    end

    # Status with silent on
    set -g _nvm_auto_use_silent 1
    set -l output (nvm_auto_use_silent 2>&1)
    if string match -q '*enabled*' "$output"
        echo "✅ Status reports enabled when silent is on"
    else
        echo "❌ Status should report enabled when silent is on"
        set failed 1
    end

    # Cleanup
    set -e _nvm_auto_use_silent

    return $failed
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
