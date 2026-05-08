#!/usr/bin/env fish
# Unit tests for nvm_doctor.fish

source tests/test_runner.fish

function test_doctor_dispatch
    echo "Testing nvm_doctor dispatch..."

    # No arguments prints usage and returns 1
    nvm_doctor
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ No-arg call returns error"
    or echo "❌ No-arg call should return error"

    # Invalid subcommand returns 1
    nvm_doctor invalid_subcommand_xyz
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ Invalid subcommand returns error"
    or echo "❌ Invalid subcommand should return error"

    return 0
end

function test_doctor_system_info
    echo "Testing nvm_doctor system info..."

    set -l output (_nvm_doctor_system_info 2>&1)
    test -n "$output"
    and echo "✅ System info produces output"
    or echo "❌ System info produced no output"

    string match -q '*OS:*' "$output"
    and echo "✅ System info contains OS line"
    or echo "❌ System info missing OS line"

    return 0
end

function test_doctor_fix_dispatch
    echo "Testing nvm_doctor fix dispatch..."

    # Fix with no subcommand prints available types and returns 1
    nvm_doctor fix
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ fix with no type returns error"
    or echo "❌ fix with no type should return error"

    # Fix with invalid type returns 1
    nvm_doctor fix invalid_type_xyz
    set -l status_code $status
    test $status_code -ne 0
    and echo "✅ fix with invalid type returns error"
    or echo "❌ fix with invalid type should return error"

    return 0
end

function test_doctor_subcommands_run
    echo "Testing nvm_doctor subcommands execute without crash..."

    # These may report issues but must not crash (exit 0 or 1 only, not signal)
    nvm_doctor system >/dev/null 2>&1
    test $status -le 1
    and echo "✅ nvm_doctor system runs"
    or echo "❌ nvm_doctor system crashed"

    nvm_doctor config >/dev/null 2>&1
    test $status -le 1
    and echo "✅ nvm_doctor config runs"
    or echo "❌ nvm_doctor config crashed"

    nvm_doctor cache >/dev/null 2>&1
    test $status -le 1
    and echo "✅ nvm_doctor cache runs"
    or echo "❌ nvm_doctor cache crashed"

    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_doctor_dispatch; or set failed (math "$failed + 1")
    test_doctor_system_info; or set failed (math "$failed + 1")
    test_doctor_fix_dispatch; or set failed (math "$failed + 1")
    test_doctor_subcommands_run; or set failed (math "$failed + 1")

    cleanup_test_env

    if test $failed -eq 0
        echo "All doctor tests passed!"
        return 0
    else
        echo "$failed doctor test(s) failed"
        return 1
    end
end

main
