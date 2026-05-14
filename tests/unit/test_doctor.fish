#!/usr/bin/env fish
# Unit tests for nvm_doctor.fish

source tests/test_runner.fish

function test_doctor_dispatch
    echo "Testing nvm_doctor dispatch..."
    set -l failed 0

    # No arguments prints usage and returns 1
    nvm_doctor
    if test $status -ne 0
        echo "✅ No-arg call returns error"
    else
        echo "❌ No-arg call should return error"
        set failed 1
    end

    # Invalid subcommand returns 1
    nvm_doctor invalid_subcommand_xyz
    if test $status -ne 0
        echo "✅ Invalid subcommand returns error"
    else
        echo "❌ Invalid subcommand should return error"
        set failed 1
    end

    return $failed
end

function test_doctor_system_info
    echo "Testing nvm_doctor system info..."
    set -l failed 0

    set -l output (_nvm_doctor_system_info 2>&1)
    if test -n "$output"
        echo "✅ System info produces output"
    else
        echo "❌ System info produced no output"
        set failed 1
    end

    if string match -q '*OS:*' "$output"
        echo "✅ System info contains OS line"
    else
        echo "❌ System info missing OS line"
        set failed 1
    end

    return $failed
end

function test_doctor_fix_dispatch
    echo "Testing nvm_doctor fix dispatch..."
    set -l failed 0

    # Fix with no subcommand prints available types and returns 1
    nvm_doctor fix
    if test $status -ne 0
        echo "✅ fix with no type returns error"
    else
        echo "❌ fix with no type should return error"
        set failed 1
    end

    # Fix with invalid type returns 1
    nvm_doctor fix invalid_type_xyz
    if test $status -ne 0
        echo "✅ fix with invalid type returns error"
    else
        echo "❌ fix with invalid type should return error"
        set failed 1
    end

    return $failed
end

function test_doctor_subcommands_run
    echo "Testing nvm_doctor subcommands execute without crash..."
    set -l failed 0

    # These may report issues but must not crash (exit 0 or 1 only, not signal)
    nvm_doctor system >/dev/null 2>&1
    if test $status -le 1
        echo "✅ nvm_doctor system runs"
    else
        echo "❌ nvm_doctor system crashed"
        set failed 1
    end

    nvm_doctor config >/dev/null 2>&1
    if test $status -le 1
        echo "✅ nvm_doctor config runs"
    else
        echo "❌ nvm_doctor config crashed"
        set failed 1
    end

    nvm_doctor cache >/dev/null 2>&1
    if test $status -le 1
        echo "✅ nvm_doctor cache runs"
    else
        echo "❌ nvm_doctor cache crashed"
        set failed 1
    end

    return $failed
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
