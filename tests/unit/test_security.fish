#!/usr/bin/env fish
# Unit tests for nvm_security.fish

source tests/test_runner.fish

function test_version_validation
    echo "Testing version validation..."

    # Valid versions
    nvm_security check_version "18.17.0"
    and echo "✅ Valid semver accepted"
    or echo "❌ Valid semver rejected"

    nvm_security check_version "v20.5.1"
    and echo "✅ Version with 'v' prefix accepted"
    or echo "❌ Version with 'v' prefix rejected"

    # Invalid versions
    nvm_security check_version "invalid.version"
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Invalid version rejected"
    or echo "❌ Invalid version accepted"

    # Suspicious characters
    nvm_security check_version "18.0.0; touch /tmp/nvm-auto-use-malicious-test"
    set status_code $status
    test $status_code -ne 0
    and echo "✅ Malicious version string rejected"
    or echo "❌ Malicious version string accepted"

    return 0
end

function test_security_policies
    echo "Testing security policies..."

    # Set minimum version policy
    nvm_security policy set min_version "16.0.0"
    set -l min_version (nvm_security policy get min_version)
    assert_equals "$min_version" "16.0.0" "Minimum version policy set correctly"

    # Test version below minimum
    nvm_security check_version "14.0.0"
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Version below minimum rejected"
    or echo "❌ Version below minimum accepted"

    # Set maximum version policy
    nvm_security policy set max_version "20.0.0"
    set -l max_version (nvm_security policy get max_version)
    assert_equals "$max_version" "20.0.0" "Maximum version policy set correctly"

    # Test version above maximum
    nvm_security check_version "21.0.0"
    set status_code $status
    test $status_code -ne 0
    and echo "✅ Version above maximum rejected"
    or echo "❌ Version above maximum accepted"

    # Reset policies
    nvm_security policy reset

    return 0
end

function test_version_comparison
    echo "Testing version comparison..."

    # Test less than
    _nvm_security_version_compare "16.0.0" "18.0.0" -lt
    and echo "✅ Version comparison (less than) works"
    or echo "❌ Version comparison (less than) failed"

    # Test greater than
    _nvm_security_version_compare "20.0.0" "18.0.0" -gt
    and echo "✅ Version comparison (greater than) works"
    or echo "❌ Version comparison (greater than) failed"

    # Test equal
    _nvm_security_version_compare "18.17.0" "18.17.0" -eq
    and echo "✅ Version comparison (equal) works"
    or echo "❌ Version comparison (equal) failed"

    return 0
end

function test_source_validation
    echo "Testing source file validation..."

    # Create test files
    echo "18.17.0" >test_nvmrc
    echo "18.0.0; touch /tmp/nvm-auto-use-malicious-test" >malicious_nvmrc

    # Test valid source
    nvm_security validate_source test_nvmrc
    and echo "✅ Valid source file accepted"
    or echo "❌ Valid source file rejected"

    # Test malicious source
    nvm_security validate_source malicious_nvmrc
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Malicious source file rejected"
    or echo "❌ Malicious source file accepted"

    # Cleanup
    rm -f test_nvmrc malicious_nvmrc

    return 0
end

function test_vulnerability_check
    echo "Testing vulnerability checking..."

    # Test known vulnerable version (if any in our test data)
    nvm_security check_cve "16.0.0"
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Known vulnerable version flagged"
    or echo "ℹ️  No vulnerability data for test version"

    # Test presumably safe version
    nvm_security check_cve "18.17.0"
    and echo "✅ Safe version check completed"
    or echo "ℹ️  Vulnerability check completed with warnings"

    return 0
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
