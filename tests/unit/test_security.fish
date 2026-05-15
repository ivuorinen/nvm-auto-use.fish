#!/usr/bin/env fish
# Unit tests for nvm_security.fish

source (path normalize (dirname (status --current-filename))/../test_runner.fish)

function test_version_validation
    echo "Testing version validation..."
    set -l failed 0

    # Valid versions
    if nvm_security check_version "18.17.0"
        echo "✅ Valid semver accepted"
    else
        echo "❌ Valid semver rejected"
        set failed 1
    end

    if nvm_security check_version "v20.5.1"
        echo "✅ Version with 'v' prefix accepted"
    else
        echo "❌ Version with 'v' prefix rejected"
        set failed 1
    end

    # Invalid versions
    nvm_security check_version "invalid.version"
    if test $status -ne 0
        echo "✅ Invalid version rejected"
    else
        echo "❌ Invalid version accepted"
        set failed 1
    end

    # Suspicious characters
    nvm_security check_version "18.0.0; touch /tmp/nvm-auto-use-malicious-test"
    set -l status_code $status
    rm -f /tmp/nvm-auto-use-malicious-test
    if test $status_code -ne 0
        echo "✅ Malicious version string rejected"
    else
        echo "❌ Malicious version string accepted"
        set failed 1
    end

    return $failed
end

function test_security_policies
    echo "Testing security policies..."
    set -l failed 0

    # Set minimum version policy
    nvm_security policy set min_version "16.0.0"
    set -l min_version (nvm_security policy get min_version)
    assert_equals "$min_version" "16.0.0" "Minimum version policy set correctly"
    or set failed 1

    # Test version below minimum
    nvm_security check_version "14.0.0"
    if test $status -ne 0
        echo "✅ Version below minimum rejected"
    else
        echo "❌ Version below minimum accepted"
        set failed 1
    end

    # Set maximum version policy
    nvm_security policy set max_version "20.0.0"
    set -l max_version (nvm_security policy get max_version)
    assert_equals "$max_version" "20.0.0" "Maximum version policy set correctly"
    or set failed 1

    # Test version above maximum
    nvm_security check_version "21.0.0"
    if test $status -ne 0
        echo "✅ Version above maximum rejected"
    else
        echo "❌ Version above maximum accepted"
        set failed 1
    end

    # Reset policies
    nvm_security policy reset

    return $failed
end

function test_version_comparison
    echo "Testing version comparison..."
    set -l failed 0

    # Test less than
    if _nvm_security_version_compare "16.0.0" "18.0.0" -lt
        echo "✅ Version comparison (less than) works"
    else
        echo "❌ Version comparison (less than) failed"
        set failed 1
    end

    # Test greater than
    if _nvm_security_version_compare "20.0.0" "18.0.0" -gt
        echo "✅ Version comparison (greater than) works"
    else
        echo "❌ Version comparison (greater than) failed"
        set failed 1
    end

    # Test equal
    if _nvm_security_version_compare "18.17.0" "18.17.0" -eq
        echo "✅ Version comparison (equal) works"
    else
        echo "❌ Version comparison (equal) failed"
        set failed 1
    end

    return $failed
end

function test_source_validation
    echo "Testing source file validation..."
    set -l failed 0

    # Create test files in isolated temp dir (not the working directory)
    set -l valid_nvmrc "$TEST_DIR/test_nvmrc"
    set -l bad_nvmrc "$TEST_DIR/malicious_nvmrc"
    echo "18.17.0" >"$valid_nvmrc"
    echo "18.0.0; touch /tmp/nvm-auto-use-malicious-test" >"$bad_nvmrc"

    # Test valid source
    if nvm_security validate_source "$valid_nvmrc"
        echo "✅ Valid source file accepted"
    else
        echo "❌ Valid source file rejected"
        set failed 1
    end

    # Test malicious source
    nvm_security validate_source "$bad_nvmrc"
    set -l status_code $status
    rm -f /tmp/nvm-auto-use-malicious-test
    if test $status_code -ne 0
        echo "✅ Malicious source file rejected"
    else
        echo "❌ Malicious source file accepted"
        set failed 1
    end

    return $failed
end

function test_vulnerability_check
    echo "Testing vulnerability checking..."
    set -l failed 0

    # The CVE check is best-effort: the offline list is intentionally sparse
    # and the online check always returns "unknown" (see _nvm_security_online_cve_check).
    # We test that the function returns without crashing and produces output,
    # not that it classifies a specific version correctly.
    set -l output (nvm_security check_cve "18.17.0" 2>&1)
    if test -n "$output"
        echo "✅ CVE check runs and produces output"
    else
        echo "❌ CVE check produced no output"
        set failed 1
    end

    # Calling with an empty version string should return 1 (invalid input)
    nvm_security check_cve ""
    if test $status -ne 0
        echo "✅ Empty version string rejected by CVE check"
    else
        echo "❌ Empty version string incorrectly accepted by CVE check"
        set failed 1
    end

    return $failed
end

function main
    setup_test_env

    set -l failed 0

    test_version_validation; or set failed (math "$failed + 1")
    test_security_policies; or set failed (math "$failed + 1")
    test_version_comparison; or set failed (math "$failed + 1")
    test_source_validation; or set failed (math "$failed + 1")
    test_vulnerability_check; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "🎉 All security tests passed!"
        return 0
    else
        echo "💥 $failed security test(s) failed"
        return 1
    end
end

main
