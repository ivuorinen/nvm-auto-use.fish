#!/usr/bin/env fish
# Unit tests for nvm_error_recovery.fish

source tests/test_runner.fish

function test_error_recovery_dispatch
    echo "Testing nvm_error_recovery dispatch..."

    # Unknown operation returns 1
    nvm_error_recovery unknown_operation_xyz
    if test $status -ne 0
        echo "✅ Unknown operation returns error"
    else
        echo "❌ Unknown operation should return error"
        return 1
    end
end

function test_error_recovery_permission_denied
    echo "Testing permission_denied recovery..."
    set -l failed 0

    # permission_denied install should print guidance and return 1
    set -l output (nvm_error_recovery permission_denied install 2>&1)
    set -l status_code $status

    if test $status_code -ne 0
        echo "✅ permission_denied returns error"
    else
        echo "❌ permission_denied should return error"
        set failed 1
    end

    if test -n "$output"
        echo "✅ permission_denied produces guidance output"
    else
        echo "❌ permission_denied should produce output"
        set failed 1
    end

    return $failed
end

function test_error_recovery_timeout
    echo "Testing timeout recovery..."
    set -l failed 0

    set -l output (nvm_error_recovery timeout install 30 2>&1)
    set -l status_code $status

    if test $status_code -ne 0
        echo "✅ timeout returns error"
    else
        echo "❌ timeout should return error"
        set failed 1
    end

    if string match -q '*timed out*' "$output"
        echo "✅ timeout mentions timed out"
    else
        echo "❌ timeout output missing 'timed out'"
        set failed 1
    end

    return $failed
end

function test_error_recovery_corruption_no_backup
    echo "Testing corruption recovery without backup..."

    nvm_error_recovery corruption "$TEST_DIR/nonexistent_file" 2>/dev/null
    if test $status -ne 0
        echo "✅ corruption with no backup returns error"
    else
        echo "❌ corruption with no backup should return error"
        return 1
    end
end

function test_error_recovery_corruption_with_backup
    echo "Testing corruption recovery with backup..."
    set -l failed 0

    set -l target_file "$TEST_DIR/test_corrupted"
    set -l backup_file "$TEST_DIR/test_corrupted.backup"
    echo corrupted >"$target_file"
    echo good_content >"$backup_file"

    if nvm_error_recovery corruption "$target_file" 2>/dev/null
        echo "✅ corruption with backup succeeds"
    else
        echo "❌ corruption with backup should succeed"
        set failed 1
    end

    set -l restored (string collect < "$target_file")
    if test "$restored" = good_content
        echo "✅ file restored from backup"
    else
        echo "❌ file content not restored correctly"
        set failed 1
    end

    return $failed
end

function test_nvm_error_recovery_try_manager_no_command
    echo "Testing _nvm_error_recovery_try_manager with missing manager..."

    # A manager that does not exist in PATH should return 1
    _nvm_error_recovery_try_manager __nonexistent_manager_xyz__ 18.0.0
    if test $status -ne 0
        echo "✅ Missing manager returns error"
    else
        echo "❌ Missing manager should return error"
        return 1
    end
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
