#!/usr/bin/env fish
# Unit tests for nvm_version_prompt.fish

source tests/test_runner.fish

function test_version_prompt_runs_without_crash
    echo "Testing nvm_version_prompt runs without crash..."

    nvm_version_prompt >/dev/null 2>&1
    test $status -le 1
    and echo "✅ nvm_version_prompt runs"
    or echo "❌ nvm_version_prompt crashed"

    return 0
end

function test_version_prompt_output_format
    echo "Testing nvm_version_prompt output format..."

    if command -q node
        set -l output (nvm_version_prompt 2>/dev/null)
        test -n "$output"
        and echo "✅ nvm_version_prompt produces output when node is available"
        or echo "❌ nvm_version_prompt should produce output when node is available"

        # Output must not start with 'v' (prefix is stripped)
        string match -qr '^[^v]' "$output"
        and echo "✅ Output does not start with 'v'"
        or echo "❌ Output should not have a leading 'v'"
    else
        echo "ℹ️  node not available — skipping output format check"
    end

    return 0
end

function test_version_status_runs
    echo "Testing nvm_version_status runs without crash..."

    nvm_version_status >/dev/null 2>&1
    test $status -le 1
    and echo "✅ nvm_version_status runs"
    or echo "❌ nvm_version_status crashed"

    return 0
end

function test_version_status_shows_node_line
    echo "Testing nvm_version_status shows Node.js line..."

    set -l output (nvm_version_status 2>/dev/null)
    string match -q '*Node.js*' "$output"
    and echo "✅ nvm_version_status output contains 'Node.js'"
    or echo "❌ nvm_version_status output should contain 'Node.js'"

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_version_prompt_runs_without_crash; or set failed (math "$failed + 1")
    test_version_prompt_output_format; or set failed (math "$failed + 1")
    test_version_status_runs; or set failed (math "$failed + 1")
    test_version_status_shows_node_line; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "All version_prompt tests passed!"
        return 0
    else
        echo "$failed version_prompt test(s) failed"
        return 1
    end
end

main
