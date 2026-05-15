#!/usr/bin/env fish
# Unit tests for nvm_version_prompt.fish

source (path normalize (dirname (status --current-filename))/../test_runner.fish)

function test_version_prompt_runs_without_crash
    echo "Testing nvm_version_prompt runs without crash..."

    nvm_version_prompt >/dev/null 2>&1
    if test $status -le 1
        echo "✅ nvm_version_prompt runs"
    else
        echo "❌ nvm_version_prompt crashed"
        return 1
    end
end

function test_version_prompt_output_format
    echo "Testing nvm_version_prompt output format..."
    set -l failed 0

    if command -q node
        set -l output (nvm_version_prompt 2>/dev/null)
        if test -n "$output"
            echo "✅ nvm_version_prompt produces output when node is available"
        else
            echo "❌ nvm_version_prompt should produce output when node is available"
            set failed 1
        end

        # Output must not start with 'v' (prefix is stripped)
        if string match -qr '^[^v]' "$output"
            echo "✅ Output does not start with 'v'"
        else
            echo "❌ Output should not have a leading 'v'"
            set failed 1
        end
    else
        echo "ℹ️  node not available — skipping output format check"
    end

    return $failed
end

function test_version_status_runs
    echo "Testing nvm_version_status runs without crash..."

    nvm_version_status >/dev/null 2>&1
    if test $status -le 1
        echo "✅ nvm_version_status runs"
    else
        echo "❌ nvm_version_status crashed"
        return 1
    end
end

function test_version_status_shows_node_line
    echo "Testing nvm_version_status shows Node.js line..."

    set -l output (nvm_version_status 2>/dev/null)
    if string match -q '*Node.js*' "$output"
        echo "✅ nvm_version_status output contains 'Node.js'"
    else
        echo "❌ nvm_version_status output should contain 'Node.js'"
        return 1
    end
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
