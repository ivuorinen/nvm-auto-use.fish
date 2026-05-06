#!/usr/bin/env fish
# Test runner for nvm-auto-use.fish

function run_tests -d "Run all tests"
    set -l test_files
    set -l failed_tests 0
    set -l total_tests 0

    echo "🧪 Running nvm-auto-use.fish test suite"
    echo "======================================"

    # Find all test files
    for test_file in tests/unit/*.fish tests/integration/*.fish
        if test -f "$test_file"
            set test_files $test_files "$test_file"
        end
    end

    if test (count $test_files) -eq 0
        echo "❌ No test files found"
        return 1
    end

    # Run each test file
    for test_file in $test_files
        set -l name (basename $test_file)
        echo
        echo "📁 Running $name"
        echo (string repeat -N (string length "📁 Running $name") -)

        set -l test_result (fish "$test_file")
        set -l test_status $status

        if test $test_status -eq 0
            echo "✅ $name passed"
        else
            echo "❌ $name failed"
            set failed_tests (math "$failed_tests + 1")
        end

        set total_tests (math "$total_tests + 1")
    end

    # Summary
    echo
    echo "📊 Test Results"
    echo "==============="
    echo "Total tests: $total_tests"
    echo "Passed: "(math "$total_tests - $failed_tests")
    echo "Failed: $failed_tests"

    if test $failed_tests -eq 0
        echo
        echo "🎉 All tests passed!"
        return 0
    else
        echo
        echo "💥 $failed_tests test(s) failed"
        return 1
    end
end

function assert_equals -d "Assert two values are equal"
    set -l actual "$argv[1]"
    set -l expected "$argv[2]"
    set -l message "$argv[3]"

    if test "$actual" = "$expected"
        echo "✅ $message"
        return 0
    else
        echo "❌ $message"
        echo "   Expected: '$expected'"
        echo "   Actual:   '$actual'"
        return 1
    end
end

function assert_not_equals -d "Assert two values are not equal"
    set -l actual "$argv[1]"
    set -l expected "$argv[2]"
    set -l message "$argv[3]"

    if test "$actual" != "$expected"
        echo "✅ $message"
        return 0
    else
        echo "❌ $message"
        echo "   Values should not be equal: '$actual'"
        return 1
    end
end

function assert_contains -d "Assert string contains substring"
    set -l string "$argv[1]"
    set -l substring "$argv[2]"
    set -l message "$argv[3]"

    if string match -q "*$substring*" "$string"
        echo "✅ $message"
        return 0
    else
        echo "❌ $message"
        echo "   String: '$string'"
        echo "   Should contain: '$substring'"
        return 1
    end
end

function assert_file_exists -d "Assert file exists"
    set -l file_path "$argv[1]"
    set -l message "$argv[2]"

    if test -f "$file_path"
        echo "✅ $message"
        return 0
    else
        echo "❌ $message"
        echo "   File not found: '$file_path'"
        return 1
    end
end

function assert_command_success -d "Assert command succeeds"
    set -l command "$argv[1]"
    set -l message "$argv[2]"

    if eval "$command" >/dev/null 2>&1
        echo "✅ $message"
        return 0
    else
        echo "❌ $message"
        echo "   Command failed: '$command'"
        return 1
    end
end

function setup_test_env -d "Set up test environment"
    # Create temporary test directory
    set -g TEST_DIR (mktemp -d)
    set -l script_dir (dirname (status -f))
    set -l repo_root (dirname $script_dir)

    # Make the project's functions autoload in tests (and in any
    # `fish -c` subshells that inherit this environment variable).
    # Also source each file so private `_nvm_*` helpers (which Fish
    # autoload won't pick up) are available to tests.
    if not contains "$repo_root/functions" $fish_function_path
        set -gx fish_function_path "$repo_root/functions" $fish_function_path
    end
    for f in "$repo_root"/functions/*.fish
        source "$f"
    end

    cd "$TEST_DIR"

    set -g TEST_FIXTURES "$script_dir/fixtures"

    # Link or copy test fixtures from tests/fixtures
    if test -d "$TEST_FIXTURES"
        cp -R "$TEST_FIXTURES" "$TEST_DIR/fixtures"
    else
        mkdir -p "$TEST_FIXTURES"
        echo "18.17.0" >"$TEST_FIXTURES/.nvmrc"
        echo "16.20.0" >"$TEST_FIXTURES/.node-version"
        echo "nodejs 20.5.0" >"$TEST_FIXTURES/.tool-versions"
        echo '{"engines": {"node": ">=18.0.0"}}' >"$TEST_FIXTURES/package.json"
    end

    echo "🔧 Test environment set up in $TEST_DIR"
end

function cleanup_test_env -d "Clean up test environment"
    if set -q TEST_DIR
        # Safety checks: never delete /, $HOME, or empty path
        if test -z "$TEST_DIR"
            echo "⚠️  TEST_DIR is empty, refusing to delete"
            return 1
        end
        if test "$TEST_DIR" = /
            echo "⚠️  TEST_DIR is /, refusing to delete"
            return 1
        end
        if test "$TEST_DIR" = "$HOME"
            echo "⚠️  TEST_DIR is $HOME, refusing to delete"
            return 1
        end
        if string match -q "$HOME*" "$TEST_DIR"; and test "$TEST_DIR" = "$HOME"
            echo "⚠️  TEST_DIR is $HOME or a parent, refusing to delete"
            return 1
        end
        if test (string length "$TEST_DIR") -lt 8
            echo "⚠️  TEST_DIR path too short, refusing to delete: $TEST_DIR"
            return 1
        end
        rm -rf "$TEST_DIR"
        echo "🧹 Test environment cleaned up"
    end
end

# Run tests if this script is executed directly (not sourced).
# `status stack-trace` includes "from sourcing file" only when sourced.
if not string match -q '*from sourcing file*' (status stack-trace)
    run_tests
end
