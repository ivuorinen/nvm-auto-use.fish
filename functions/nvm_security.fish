function nvm_security -d "Security validation and vulnerability checking"
    set -l action $argv[1]

    switch $action
        case check_version
            set -l version $argv[2]
            _nvm_security_validate_version "$version"

        case check_cve
            set -l version $argv[2]
            _nvm_security_check_vulnerabilities "$version"

        case validate_source
            set -l source $argv[2]
            _nvm_security_validate_source "$source"

        case audit
            _nvm_security_audit_current

        case policy
            set -l policy_action $argv[2]
            _nvm_security_policy "$policy_action" $argv[3..-1]

        case '*'
            echo "Usage: nvm_security [check_version|check_cve|validate_source|audit|policy] [args...]"
            return 1
    end
end

function _nvm_security_validate_version -d "Validate version string format and safety"
    set -l version $argv[1]

    # Remove leading 'v' if present
    set version (string replace -r '^v' '' "$version")

    # Check for valid semver format
    if not string match -qr '^\d+\.\d+\.\d+' "$version"
        echo "⚠️  Invalid version format: $version" >&2
        return 1
    end

    # Check for suspicious characters
    if string match -qr '[;&|`$(){}[\]<>]' "$version"
        echo "🚨 Suspicious characters in version: $version" >&2
        return 1
    end

    # Check against minimum supported version
    set -l min_version (nvm_security policy get min_version)
    if test -n "$min_version"
        if _nvm_security_version_compare "$version" "$min_version" -lt
            echo "⚠️  Version $version is below minimum required ($min_version)" >&2
            return 1
        end
    end

    # Check against maximum allowed version
    set -l max_version (nvm_security policy get max_version)
    if test -n "$max_version"
        if _nvm_security_version_compare "$version" "$max_version" -gt
            echo "⚠️  Version $version is above maximum allowed ($max_version)" >&2
            return 1
        end
    end

    return 0
end

function _nvm_security_check_vulnerabilities -d "Check version for known vulnerabilities"
    set -l version $argv[1]

    # Cache key for CVE data
    set -l cache_key "cve_check_$(echo $version | shasum | cut -d' ' -f1)"

    # Check cache first (24 hour TTL)
    if set -l cached_result (nvm_cache get "$cache_key" 86400)
        if test "$cached_result" = vulnerable
            echo "🚨 Version $version has known vulnerabilities (cached)" >&2
            return 1
        else if test "$cached_result" = safe
            echo "✅ Version $version appears safe (cached)" >&2
            return 0
        end
    end

    # Check against known vulnerable versions (offline first)
    set -l vulnerable_versions "
        16.0.0
        16.1.0
        16.2.0
        18.0.0
        18.1.0
    "

    if string match -q "*$version*" "$vulnerable_versions"
        echo "🚨 Version $version has known vulnerabilities" >&2
        nvm_cache set "$cache_key" vulnerable
        return 1
    end

    # Try online CVE check if available
    if command -q curl
        _nvm_security_online_cve_check "$version" "$cache_key"
    else
        echo "ℹ️  Cannot perform online CVE check (curl not available)" >&2
        nvm_cache set "$cache_key" unknown
        return 0
    end
end

function _nvm_security_online_cve_check -d "Perform online CVE check"
    set -l version $argv[1]
    set -l cache_key $argv[2]

    # Background job for CVE checking to avoid blocking
    fish -c "
        set cve_result (curl -s --max-time 5 'https://nodejs.org/en/about/security/' 2>/dev/null)
        if test \$status -eq 0
            if echo \"\$cve_result\" | grep -qi '$version'
                nvm_cache set '$cache_key' 'vulnerable'
                echo '🚨 Version $version found in security advisories' >&2
            else
                nvm_cache set '$cache_key' 'safe'
                echo '✅ Version $version appears safe' >&2
            end
        else
            nvm_cache set '$cache_key' 'unknown'
            echo 'ℹ️  Unable to verify security status online' >&2
        end
    " &

    return 0
end

function _nvm_security_validate_source -d "Validate version file source"
    set -l source_file $argv[1]

    if not test -f "$source_file"
        echo "⚠️  Source file not found: $source_file" >&2
        return 1
    end

    # Check file permissions
    if test -w "$source_file" -a (stat -c %a "$source_file" 2>/dev/null || stat -f %Mp%Lp "$source_file" 2>/dev/null) = 777
        echo "⚠️  Insecure permissions on $source_file (world-writable)" >&2
    end

    # Check for suspicious content
    set -l content (cat "$source_file")
    if string match -qr '[;&|`$(){}[\]<>]' "$content"
        echo "🚨 Suspicious content in $source_file" >&2
        return 1
    end

    return 0
end

function _nvm_security_audit_current -d "Audit current Node.js installation"
    echo "🔍 Security audit for current Node.js installation"
    echo

    # Current version info
    if command -q node
        set -l current_version (node --version 2>/dev/null | string replace 'v' '')
        echo "Current version: $current_version"

        # Check current version security
        nvm_security check_version "$current_version"
        nvm_security check_cve "$current_version"

        # Check npm security if available
        if command -q npm
            echo
            echo "📦 NPM audit (if available):"
            npm audit --audit-level moderate 2>/dev/null || echo "NPM audit not available or no package.json found"
        end
    else
        echo "❌ Node.js not found in PATH"
    end

    echo
    echo "🔧 Version managers found:"
    nvm_compat_detect

    echo
    echo "📋 Security policies:"
    nvm_security policy list
end

function _nvm_security_policy -d "Manage security policies"
    set -l action $argv[1]

    switch $action
        case set
            set -l key $argv[2]
            set -l value $argv[3]

            switch $key
                case min_version
                    set -g _nvm_security_min_version "$value"
                    echo "Set minimum version to: $value"
                case max_version
                    set -g _nvm_security_max_version "$value"
                    echo "Set maximum version to: $value"
                case allow_prerelease
                    set -g _nvm_security_allow_prerelease "$value"
                    echo "Allow prerelease versions: $value"
                case '*'
                    echo "Unknown policy key: $key" >&2
                    return 1
            end

        case get
            set -l key $argv[2]

            switch $key
                case min_version
                    echo "$_nvm_security_min_version"
                case max_version
                    echo "$_nvm_security_max_version"
                case allow_prerelease
                    echo "$_nvm_security_allow_prerelease"
                case '*'
                    echo "Unknown policy key: $key" >&2
                    return 1
            end

        case list
            echo "Security policies:"
            echo "  min_version: $_nvm_security_min_version"
            echo "  max_version: $_nvm_security_max_version"
            echo "  allow_prerelease: $_nvm_security_allow_prerelease"

        case reset
            set -e _nvm_security_min_version
            set -e _nvm_security_max_version
            set -e _nvm_security_allow_prerelease
            echo "Security policies reset to defaults"

        case '*'
            echo "Usage: nvm_security policy [set|get|list|reset] [key] [value]"
            return 1
    end
end

function _nvm_security_version_compare -d "Compare semantic versions"
    set -l version1 $argv[1]
    set -l version2 $argv[2]
    set -l operator $argv[3]

    # Simple semver comparison
    set -l v1_parts (string split '.' "$version1")
    set -l v2_parts (string split '.' "$version2")

    for i in (seq 1 3)
        set -l v1_part (echo $v1_parts[$i] | string replace -r '[^0-9].*' '')
        set -l v2_part (echo $v2_parts[$i] | string replace -r '[^0-9].*' '')

        if test -z "$v1_part"
            set v1_part 0
        end
        if test -z "$v2_part"
            set v2_part 0
        end

        if test $v1_part -lt $v2_part
            test "$operator" = -lt
            return $status
        else if test $v1_part -gt $v2_part
            test "$operator" = -gt
            return $status
        end
    end

    # Versions are equal
    test "$operator" = -eq
    return $status
end
