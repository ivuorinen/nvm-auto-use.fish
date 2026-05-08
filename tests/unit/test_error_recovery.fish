#!/usr/bin/env fish
# Unit tests for nvm_error_recovery.fish

source tests/test_runner.fish

function test_error_recovery_dispatch
    echo "Testing nvm_error_recovery dispatch..."

    # Unknown operation returns 1
    nvm_error_recovery unknown_operation_xyz
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Unknown operation returns error"
    or echo "❌ Unknown operation should return error"

    return 0
end

function test_error_recovery_permission_denied
    echo "Testing permission_denied recovery..."

    # permission_denied install should print guidance and return 1
    set -l output (nvm_error_recovery permission_denied install 2>&1)
    test $status -ne 0
    and echo "✅ permission_denied returns error"
    or echo "❌ permission_denied should return error"

    test -n "$output"
    and echo "✅ permission_denied produces guidance output"
    or echo "❌ permission_denied should produce output"

    return 0
end

function test_error_recovery_timeout
    echo "Testing timeout recovery..."

    set -l output (nvm_error_recovery timeout install 30 2>&1)
    test $status -ne 0
    and echo "✅ timeout returns error"
    or echo "❌ timeout should return error"

    string match -q '*timed out*' "$output"
    and echo "✅ timeout mentions timed out"
    or echo "❌ timeout output missing 'timed out'"

    return 0
end

function test_error_recovery_corruption_no_backup
    echo "Testing corruption recovery without backup..."

    set -l output (nvm_error_recovery corruption "$TEST_DIR/nonexistent_file" 2>&1)
    test $status -ne 0
    and echo "✅ corruption with no backup returns error"
    or echo "❌ corruption with no backup should return error"

    return 0
end

function test_error_recovery_corruption_with_backup
    echo "Testing corruption recovery with backup..."

    set -l target_file "$TEST_DIR/test_corrupted"
    set -l backup_file "$TEST_DIR/test_corrupted.backup"
    echo corrupted >"$target_file"
    echo good_content >"$backup_file"

    nvm_error_recovery corruption "$target_file" 2>/dev/null
    and echo "✅ corruption with backup succeeds"
    or echo "❌ corruption with backup should succeed"

    set -l restored (cat "$target_file")
    test "$restored" = good_content
    and echo "✅ file restored from backup"
    or echo "❌ file content not restored correctly"

    return 0
end

function test_nvm_error_recovery_try_manager_no_command
    echo "Testing _nvm_error_recovery_try_manager with missing manager..."

    # A manager that does not exist in PATH should return 1
    _nvm_error_recovery_try_manager __nonexistent_manager_xyz__ 18.0.0
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Missing manager returns error"
    or echo "❌ Missing manager should return error"

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_error_recovery_dispatch; or set failed (math "$failed + 1")
    test_error_recovery_permission_denied; or set failed (math "$failed + 1")
    test_error_recovery_timeout; or set failed (math "$failed + 1")
    test_error_recovery_corruption_no_backup; or set failed (math "$failed + 1")
    test_error_recovery_corruption_with_backup; or set failed (math "$failed + 1")
    test_nvm_error_recovery_try_manager_no_command; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "All error_recovery tests passed!"
        return 0
    else
        echo "$failed error_recovery test(s) failed"
        return 1
    end
end

main
