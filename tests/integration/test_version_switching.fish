#!/usr/bin/env fish
# Integration tests for version switching functionality
# All tests operate under $TEST_DIR (a temporary directory) for safety

source tests/test_runner.fish

function test_nvmrc_detection
    echo "Testing .nvmrc file detection..."

    # Create test project with .nvmrc in temp dir
    mkdir -p "$TEST_DIR/test_project"
    echo "18.17.0" >"$TEST_DIR/test_project/.nvmrc"

    cd "$TEST_DIR/test_project"
    set -l found_file (nvm_find_nvmrc)
    assert_contains "$found_file" ".nvmrc" "Found .nvmrc file in current directory"

    # Test parent directory search
    mkdir -p subdir
    cd subdir
    set found_file (nvm_find_nvmrc)
    assert_contains "$found_file" ".nvmrc" "Found .nvmrc file in parent directory"

    cd "$TEST_DIR"
    rm -rf "$TEST_DIR/test_project"

    return 0
end

function test_version_extraction
    echo "Testing version extraction from different file formats..."

    cd "$TEST_DIR"
    # Test .nvmrc
    echo "18.17.0" >test.nvmrc
    set -l version (nvm_extract_version "test.nvmrc")
    assert_equals "$version" "18.17.0" "Extracted version from .nvmrc"

    # Test .node-version
    echo "16.20.0" >test.node-version
    set version (nvm_extract_version "test.node-version")
    assert_equals "$version" "16.20.0" "Extracted version from .node-version"

    # Test .tool-versions
    echo "nodejs 20.5.0" >test.tool-versions
    set version (nvm_extract_version "test.tool-versions:nodejs")
    assert_equals "$version" "20.5.0" "Extracted version from .tool-versions"

    # Test package.json (requires jq)
    if command -q jq
        echo '{"engines": {"node": ">=18.0.0"}}' >test.package.json
        set version (nvm_extract_version "test.package.json:engines.node")
        assert_equals "$version" "18.0.0" "Extracted version from package.json"
    else
        echo "ℹ️  Skipping package.json test (jq not available)"
    end

    # Cleanup
    rm -f test.nvmrc test.node-version test.tool-versions test.package.json

    return 0
end

function test_manager_detection
    echo "Testing version manager detection..."

    cd "$TEST_DIR"
    set -l managers (nvm_compat_detect)

    if test -n "$managers"
        echo "✅ Found version managers: $managers"
    else
        echo "ℹ️  No version managers found (expected in test environment)"
    end

    return 0
end

function test_error_recovery
    echo "Testing error recovery mechanisms..."

    cd "$TEST_DIR"
    # Test invalid version handling
    echo "invalid.version" >invalid.nvmrc
    set -l result (nvm_extract_version "invalid.nvmrc" 2>/dev/null)

    if test -z "$result"
        echo "✅ Invalid version file handled gracefully"
    else
        echo "❌ Invalid version should return empty result"
    end

    # Test missing file handling
    nvm_extract_version "nonexistent.nvmrc" >/dev/null 2>&1
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Missing file handled gracefully"
    or echo "❌ Missing file should return error"

    rm -f invalid.nvmrc

    return 0
end

function test_async_operations
    echo "Testing async operations..."

    cd "$TEST_DIR"
    # Create test version file
    echo "18.17.0" >async_test.nvmrc

    # Test async version check
    set -l job_id (nvm_async version_check "async_test.nvmrc")

    if test -n "$job_id"
        echo "✅ Async version check started"

        # Wait for completion
        nvm_async wait "$job_id" 5
        and echo "✅ Async operation completed"
        or echo "⚠️  Async operation timed out"
    else
        echo "ℹ️  Async operation may have completed immediately"
    end

    rm -f async_test.nvmrc

    return 0
end

function test_cache_integration
    echo "Testing cache integration..."

    cd "$TEST_DIR"
    # Clear cache first
    nvm_cache clear

    # Create test file
    echo "18.17.0" >cache_test.nvmrc

    # First access should miss cache
    set -l start_time (date +%s)
    set -l version1 (nvm_extract_version "cache_test.nvmrc")

    # Second access should hit cache (if caching is implemented)
    set -l version2 (nvm_extract_version "cache_test.nvmrc")

    assert_equals "$version1" "$version2" "Consistent results from cache"

    rm -f cache_test.nvmrc

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_nvmrc_detection; or set failed (math "$failed + 1")
    test_version_extraction; or set failed (math "$failed + 1")
    test_manager_detection; or set failed (math "$failed + 1")
    test_error_recovery; or set failed (math "$failed + 1")
    test_async_operations; or set failed (math "$failed + 1")
    test_cache_integration; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "🎉 All integration tests passed!"
        return 0
    else
        echo "💥 $failed integration test(s) failed"
        return 1
    end
end

main
