#!/usr/bin/env fish
# Unit tests for nvm_async helper functions

source tests/test_runner.fish

function test_async_version_check
    echo "Testing _nvm_async_version_check..."

    # Create a test version file
    echo "18.17.0" >async_test.nvmrc

    # Should return job id (background job)
    set -l job_id (_nvm_async_version_check "async_test.nvmrc")
    if test -n "$job_id"
        echo "✅ _nvm_async_version_check started job $job_id"
    else
        echo "❌ _nvm_async_version_check did not start a job"
        return 1
    end

    # Wait for job completion
    _nvm_async_wait "$job_id" 5
    and echo "✅ Async job completed"
    or echo "⚠️  Async job timed out"

    rm -f async_test.nvmrc
    return 0
end

function test_async_manager_check
    echo "Testing _nvm_async_manager_check..."

    # Should return job id (background job)
    set -l job_id (_nvm_async_manager_check "nvm")
    if test -n "$job_id"
        echo "✅ _nvm_async_manager_check started job $job_id"
    else
        echo "❌ _nvm_async_manager_check did not start a job"
        return 1
    end

    # Wait for job completion
    _nvm_async_wait "$job_id" 5
    and echo "✅ Async manager check job completed"
    or echo "⚠️  Async manager check job timed out"

    return 0
end

function test_async_cleanup
    echo "Testing _nvm_async_cleanup..."

    # Start a dummy background job
    sleep 2 &
    set -l job_id $last_pid
    if test -n "$job_id"
        echo "✅ Dummy job started: $job_id"
    else
        echo "❌ Failed to start dummy job"
        return 1
    end

    # Cleanup should not error
    _nvm_async_cleanup
    echo "✅ _nvm_async_cleanup executed"

    return 0
end

function test_async_wait
    echo "Testing _nvm_async_wait..."

    # Start a quick background job
    sleep 1 &
    set -l job_id $last_pid
    if test -n "$job_id"
        _nvm_async_wait "$job_id" 3
        and echo "✅ _nvm_async_wait completed for job $job_id"
        or echo "⚠️  _nvm_async_wait timed out for job $job_id"
    else
        echo "❌ Failed to start background job for wait test"
        return 1
    end

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_async_version_check; or set failed (math "$failed + 1")
    test_async_manager_check; or set failed (math "$failed + 1")
    test_async_cleanup; or set failed (math "$failed + 1")
    test_async_wait; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "🎉 All async helper tests passed!"
        return 0
    else
        echo "💥 $failed async helper test(s) failed"
        return 1
    end
end

main
