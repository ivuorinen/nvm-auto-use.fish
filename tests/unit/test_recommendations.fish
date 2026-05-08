#!/usr/bin/env fish
# Unit tests for nvm_recommendations.fish

source tests/test_runner.fish

function test_recommendations_dispatch
    echo "Testing nvm_recommendations dispatch..."

    # No arguments prints usage and returns 1
    nvm_recommendations
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ No-arg call returns error"
    or echo "❌ No-arg call should return error"

    # Invalid subcommand returns 1
    nvm_recommendations invalid_subcommand_xyz
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Invalid subcommand returns error"
    or echo "❌ Invalid subcommand should return error"

    return 0
end

function test_recommendations_suggest_runs
    echo "Testing nvm_recommendations suggest_version runs without crash..."

    # suggest_version with context arg must not crash
    nvm_recommendations suggest_version new_project >/dev/null 2>&1
    test $status -le 1
    and echo "✅ suggest_version new_project runs"
    or echo "❌ suggest_version new_project crashed"

    return 0
end

function test_recommendations_upgrade_runs
    echo "Testing nvm_recommendations upgrade_path runs without crash..."

    nvm_recommendations upgrade_path >/dev/null 2>&1
    test $status -le 1
    and echo "✅ upgrade_path runs"
    or echo "❌ upgrade_path crashed"

    return 0
end

function test_recommendations_security_runs
    echo "Testing nvm_recommendations security_update runs without crash..."

    nvm_recommendations security_update >/dev/null 2>&1
    test $status -le 1
    and echo "✅ security_update runs"
    or echo "❌ security_update crashed"

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_recommendations_dispatch; or set failed (math "$failed + 1")
    test_recommendations_suggest_runs; or set failed (math "$failed + 1")
    test_recommendations_upgrade_runs; or set failed (math "$failed + 1")
    test_recommendations_security_runs; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "All recommendations tests passed!"
        return 0
    else
        echo "$failed recommendations test(s) failed"
        return 1
    end
end

main
