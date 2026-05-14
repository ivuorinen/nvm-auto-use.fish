#!/usr/bin/env fish
# Unit tests for nvm_notify.fish

source tests/test_runner.fish

function test_notify_empty_message
    echo "Testing nvm_notify with empty message..."

    nvm_notify ""
    if test $status -ne 0
        echo "✅ Empty message returns error"
    else
        echo "❌ Empty message should return error"
        return 1
    end
end

function test_notify_suppressed_when_disabled
    echo "Testing nvm_notify respects _nvm_auto_use_no_notifications..."

    set -g _nvm_auto_use_no_notifications 1
    nvm_notify "test message"
    set -l status_code $status
    set -e _nvm_auto_use_no_notifications

    if test $status_code -eq 0
        echo "✅ Notification suppressed when disabled"
    else
        echo "❌ Notification should be suppressed when disabled"
        return 1
    end
end

function test_notify_with_message_does_not_crash
    echo "Testing nvm_notify with message does not crash..."

    # Suppress notifications so no system dialog appears during tests
    set -g _nvm_auto_use_no_notifications 1
    nvm_notify "Node.js v18.0.0" >/dev/null 2>&1
    set -l status_code $status
    set -e _nvm_auto_use_no_notifications

    if test $status_code -eq 0
        echo "✅ nvm_notify runs without crashing"
    else
        echo "❌ nvm_notify returned failure unexpectedly"
        return 1
    end
end

function main
    setup_test_env

    set -l failed 0

    test_notify_empty_message; or set failed (math "$failed + 1")
    test_notify_suppressed_when_disabled; or set failed (math "$failed + 1")
    test_notify_with_message_does_not_crash; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "All notify tests passed!"
        return 0
    else
        echo "$failed notify test(s) failed"
        return 1
    end
end

main
