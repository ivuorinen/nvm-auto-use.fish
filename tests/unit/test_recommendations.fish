#!/usr/bin/env fish
# Unit tests for nvm_recommendations.fish

source tests/test_runner.fish

function test_recommendations_dispatch
    echo "Testing nvm_recommendations dispatch..."
    set -l failed 0

    # No arguments prints usage and returns 1
    nvm_recommendations
    if test $status -ne 0
        echo "✅ No-arg call returns error"
    else
        echo "❌ No-arg call should return error"
        set failed 1
    end

    # Invalid subcommand returns 1
    nvm_recommendations invalid_subcommand_xyz
    if test $status -ne 0
        echo "✅ Invalid subcommand returns error"
    else
        echo "❌ Invalid subcommand should return error"
        set failed 1
    end

    return $failed
end

function test_recommendations_suggest_runs
    echo "Testing nvm_recommendations suggest_version runs without crash..."

    # suggest_version with context arg must not crash
    nvm_recommendations suggest_version new_project >/dev/null 2>&1
    if test $status -le 1
        echo "✅ suggest_version new_project runs"
    else
        echo "❌ suggest_version new_project crashed"
        return 1
    end
end

function test_recommendations_upgrade_runs
    echo "Testing nvm_recommendations upgrade_path runs without crash..."

    nvm_recommendations upgrade_path >/dev/null 2>&1
    if test $status -le 1
        echo "✅ upgrade_path runs"
    else
        echo "❌ upgrade_path crashed"
        return 1
    end
end

function test_recommendations_security_runs
    echo "Testing nvm_recommendations security_update runs without crash..."

    nvm_recommendations security_update >/dev/null 2>&1
    if test $status -le 1
        echo "✅ security_update runs"
    else
        echo "❌ security_update crashed"
        return 1
    end
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
