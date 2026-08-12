#!/usr/bin/env fish
# Unit tests for nvm_doctor.fish

source (path normalize (dirname (status --current-filename))/../test_runner.fish)

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

function test_doctor_old_cache_file_count
    echo "Testing nvm_doctor reports the real count of stale cache files..."

    # setup_test_env points XDG_CACHE_HOME at the temp dir.
    set -l cache_dir "$XDG_CACHE_HOME/nvm-auto-use"
    nvm_cache clear
    mkdir -p "$cache_dir"

    # -t takes POSIX [[CC]YY]MMDDhhmm and works on both GNU and BSD touch.
    for name in stale_a stale_b stale_c
        echo value >"$cache_dir/$name"
        touch -t 202001010000 "$cache_dir/$name"
    end

    set -l output (_nvm_doctor_check_cache 2>&1 | string collect)

    assert_contains "$output" "Found 3 cache files 7 days or older" \
        "Stale cache file count reflects the actual number of files"
    or return 1

    # Boundary: -mtime truncates, so `+7` would silently skip the 7-to-8-day
    # window. A file aged 7.5 days must be counted. The ancient files above
    # cannot detect this — they match either spelling.
    # `touch -d <relative>` is GNU-only; skip the check where it is missing.
    if touch -d "180 hours ago" "$cache_dir/boundary" 2>/dev/null
        set -l boundary_output (_nvm_doctor_check_cache 2>&1 | string collect)
        assert_contains "$boundary_output" "Found 4 cache files 7 days or older" \
            "A cache file aged 7.5 days counts as 7 days or older"
        or return 1
    else
        echo "ℹ️  Skipping 7-day boundary check (touch -d unavailable)"
    end

    nvm_cache clear
    return 0
end

function main
    setup_test_env

    set -l failed 0

    test_doctor_dispatch; or set failed (math "$failed + 1")
    test_doctor_system_info; or set failed (math "$failed + 1")
    test_doctor_old_cache_file_count; or set failed (math "$failed + 1")
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
