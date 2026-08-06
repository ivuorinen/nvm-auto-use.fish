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

function assert_not_contains -d "Assert string does not contain substring"
    set -l string "$argv[1]"
    set -l substring "$argv[2]"
    set -l message "$argv[3]"

    if not string match -q "*$substring*" "$string"
        echo "✅ $message"
        return 0
    else
        echo "❌ $message"
        echo "   String: '$string'"
        echo "   Should not contain: '$substring'"
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
    # Resolve to an absolute path before the `cd "$TEST_DIR"` below: `status -f`
    # is relative when tests are invoked as `fish tests/unit/foo.fish`, which
    # left a relative "./functions" in $fish_function_path that no longer
    # resolved once the shell moved into the temp dir.
    set -l script_dir (path dirname (path resolve (status -f)))
    set -l repo_root (path dirname $script_dir)

    # Fisher installs this plugin into $XDG_CONFIG_HOME/fish/functions, which
    # every child `fish -c` autoloads from. Mirror that layout so background
    # jobs spawned by nvm_async can resolve nvm_* functions.
    #
    # Exporting $fish_function_path instead does NOT work: fish joins list
    # variables with spaces on export, and does not re-split this one on
    # import, so the child receives the whole path list as a single bogus
    # element and autoloads nothing.
    #
    # Only fish's own directory is replaced; every other entry is symlinked
    # through to the real config, so tool managers that key off
    # XDG_CONFIG_HOME (mise, asdf) still resolve the binaries the tests shell
    # out to — `fd` and `jq` among them.
    set -l real_config "$HOME/.config"
    if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
        set real_config "$XDG_CONFIG_HOME"
    end
    set -gx XDG_CONFIG_HOME "$TEST_DIR/config"
    mkdir -p "$XDG_CONFIG_HOME/fish/functions"
    for entry in (find "$real_config" -maxdepth 1 -mindepth 1 2>/dev/null)
        set -l name (path basename "$entry")
        test "$name" = fish; and continue
        ln -sfn "$entry" "$XDG_CONFIG_HOME/$name"
    end

    # Keep cache writes inside the temp dir. Tests call `nvm_cache clear`,
    # which would otherwise wipe the developer's real ~/.cache/nvm-auto-use.
    set -gx XDG_CACHE_HOME "$TEST_DIR/cache"
    mkdir -p "$XDG_CACHE_HOME"

    # Link each module for child-shell autoload, and source it so private
    # `_nvm_*` helpers (which Fish autoload won't pick up) are available here.
    for f in "$repo_root"/functions/*.fish
        ln -sf "$f" "$XDG_CONFIG_HOME/fish/functions/"(path basename "$f")
        source "$f"
    end

    cd "$TEST_DIR"

    # Always create fresh fixtures in the temp dir; never rely on a cached
    # tests/fixtures/ directory that may carry stale state from prior runs.
    set -g TEST_FIXTURES "$TEST_DIR/fixtures"
    mkdir -p "$TEST_FIXTURES"
    echo "18.17.0" >"$TEST_FIXTURES/.nvmrc"
    echo "16.20.0" >"$TEST_FIXTURES/.node-version"
    echo "nodejs 20.5.0" >"$TEST_FIXTURES/.tool-versions"
    echo '{"engines": {"node": ">=18.0.0"}}' >"$TEST_FIXTURES/package.json"

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
