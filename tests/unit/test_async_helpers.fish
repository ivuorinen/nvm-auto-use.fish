#!/usr/bin/env fish
# Unit tests for nvm_async helper functions

source (path normalize (dirname (status --current-filename))/../test_runner.fish)

function test_async_version_check
    echo "Testing _nvm_async_version_check..."
    set -l failed 0

    echo "18.17.0" >async_test.nvmrc

    # Cache hit → empty return; cache miss → PID.
    set -l job_id (_nvm_async_version_check "async_test.nvmrc")
    if test -n "$job_id"
        echo "✅ _nvm_async_version_check started background job $job_id"
        if not _nvm_async_wait "$job_id" 5
            echo "❌ Async version check timed out"
            set failed 1
        else
            echo "✅ Async job completed"
        end
    else
        echo "✅ Version resolved from cache (no background job needed)"
    end

    rm -f async_test.nvmrc
    return $failed
end

function test_async_manager_check
    echo "Testing _nvm_async_manager_check..."

    # Cache hit → empty return; cache miss → PID.
    set -l job_id (_nvm_async_manager_check "nvm")
    if test -n "$job_id"
        echo "✅ _nvm_async_manager_check started background job $job_id"
        if not _nvm_async_wait "$job_id" 5
            echo "❌ Async manager check timed out"
            return 1
        else
            echo "✅ Async manager check completed"
        end
    else
        echo "✅ Manager availability resolved from cache (no background job needed)"
    end

    return 0
end

function test_async_cleanup
    echo "Testing _nvm_async_cleanup..."

    # Use a short-lived job so it finishes before the test suite ends.
    sleep 0.1 &
    set -l job_id $last_pid
    if test -n "$job_id"
        echo "✅ Dummy job started: $job_id"
    else
        echo "❌ Failed to start dummy job"
        return 1
    end

    # Cleanup should not error whether the job is still running or done.
    _nvm_async_cleanup
    echo "✅ _nvm_async_cleanup executed"

    # Prevent the job from leaking into later tests.
    kill $job_id 2>/dev/null
    wait $job_id 2>/dev/null

    return 0
end

function test_async_wait
    echo "Testing _nvm_async_wait..."

    # Start a quick background job
    sleep 1 &
    set -l job_id $last_pid
    if test -n "$job_id"
        if not _nvm_async_wait "$job_id" 3
            echo "❌ _nvm_async_wait timed out for job $job_id"
            return 1
        end
        echo "✅ _nvm_async_wait completed for job $job_id"
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
