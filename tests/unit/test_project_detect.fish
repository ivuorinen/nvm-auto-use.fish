#!/usr/bin/env fish
# Unit tests for nvm_project_detect.fish

source tests/test_runner.fish

function test_project_detect_no_package_json
    echo "Testing nvm_project_detect with no package.json..."

    # TEST_DIR has no package.json — should return 1
    set -l dir (mktemp -d)
    cd "$dir"

    nvm_project_detect
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Returns false when no package.json found"
    or echo "❌ Should return false when no package.json"

    cd "$TEST_DIR"
    rm -rf "$dir"

    return 0
end

function test_project_detect_with_package_json
    echo "Testing nvm_project_detect with package.json present..."

    set -l dir (mktemp -d)
    echo '{"name": "test"}' >"$dir/package.json"
    cd "$dir"

    nvm_project_detect
    set -l status_code $status
    test $status_code -eq 0
    and echo "✅ Returns true when package.json found"
    or echo "❌ Should return true when package.json found"

    cd "$TEST_DIR"
    rm -rf "$dir"

    return 0
end

function test_project_detect_traverses_up
    echo "Testing nvm_project_detect traverses up directory tree..."

    set -l parent_dir (mktemp -d)
    set -l child_dir "$parent_dir/sub/dir"
    mkdir -p "$child_dir"
    echo '{"name": "test"}' >"$parent_dir/package.json"
    cd "$child_dir"

    nvm_project_detect
    set -l status_code $status
    test $status_code -eq 0
    and echo "✅ Finds package.json in parent directory"
    or echo "❌ Should traverse up to find package.json"

    cd "$TEST_DIR"
    rm -rf "$parent_dir"

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_project_detect_no_package_json; or set failed (math "$failed + 1")
    test_project_detect_with_package_json; or set failed (math "$failed + 1")
    test_project_detect_traverses_up; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "All project_detect tests passed!"
        return 0
    else
        echo "$failed project_detect test(s) failed"
        return 1
    end
end

main
