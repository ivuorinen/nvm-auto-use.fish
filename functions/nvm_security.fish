function nvm_security -d "Security validation and vulnerability checking"
    set -l action $argv[1]

    switch $action
        case check_version
            set -l node_version $argv[2]
            _nvm_security_validate_version "$node_version"

        case check_cve
            set -l node_version $argv[2]
            _nvm_security_check_vulnerabilities "$node_version"

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
    set -l node_version $argv[1]

    # Remove leading 'v' if present
    set node_version (string replace -r '^v' '' "$node_version")

    # Check semver format; allow prerelease suffix when policy is enabled
    set -l semver_pattern '^\d+\.\d+\.\d+$'
    set -l allow_prerelease (nvm_security policy get allow_prerelease)
    if test "$allow_prerelease" = 1 -o "$allow_prerelease" = true \
            -o "$allow_prerelease" = on
        set semver_pattern '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$'
    end
    if not string match -qr $semver_pattern "$node_version"
        echo "⚠️  Invalid version format: $node_version" >&2
        return 1
    end

    # Check for suspicious characters
    if string match -qr '[;&|`$(){}[\]<>]' "$node_version"
        echo "🚨 Suspicious characters in version: $node_version" >&2
        return 1
    end

    # Check against minimum supported version
    set -l min_version (nvm_security policy get min_version)
    if test -n "$min_version"
        if _nvm_security_version_compare "$node_version" "$min_version" -lt
            echo "⚠️  Version $node_version is below minimum required ($min_version)" >&2
            return 1
        end
    end

    # Check against maximum allowed version
    set -l max_version (nvm_security policy get max_version)
    if test -n "$max_version"
        if _nvm_security_version_compare "$node_version" "$max_version" -gt
            echo "⚠️  Version $node_version is above maximum allowed ($max_version)" >&2
            return 1
        end
    end

    return 0
end

function _nvm_security_check_vulnerabilities -d "Check version for known vulnerabilities"
    set -l node_version $argv[1]

    if test -z "$node_version"
        echo "⚠️  No version specified for CVE check" >&2
        return 1
    end

    # Cache key for CVE data
    set -l cache_key "cve_check_"(_nvm_security_hash "$node_version")

    # Check cache first (24 hour TTL)
    if set -l cached_result (nvm_cache get "$cache_key" 86400)
        if test "$cached_result" = vulnerable
            echo "🚨 Version $node_version has known vulnerabilities (cached)" >&2
            return 1
        else if test "$cached_result" = safe
            echo "✅ Version $node_version appears safe (cached)" >&2
            return 0
        else if test "$cached_result" = unknown
            echo "ℹ️  Security status for $node_version is unknown (cached)" >&2
            return 0
        end
    end

    # Check against known vulnerable versions (offline, exact match)
    set -l vulnerable_versions 16.0.0 16.1.0 16.2.0 18.0.0 18.1.0

    if contains -- "$node_version" $vulnerable_versions
        echo "🚨 Version $node_version has known vulnerabilities" >&2
        nvm_cache set "$cache_key" vulnerable
        return 1
    end

    # Try online CVE check if available
    if command -q curl
        _nvm_security_online_cve_check "$node_version" "$cache_key"
    else
        echo "ℹ️  Cannot perform online CVE check (curl not available)" >&2
        nvm_cache set "$cache_key" unknown
        return 0
    end
end

function _nvm_security_online_cve_check -d "Perform online CVE check"
    # Best-effort online check. Grepping HTML for the version string is too
    # noisy to reliably classify a version as vulnerable/safe (e.g. ranges
    # like "< 18.2.0" or benign "fixed in" mentions trip plain substring
    # matches). Until a structured advisory feed is wired up, always persist
    # `unknown` regardless of the HTTP response.
    # TODO: wire up a structured JSON advisory feed (e.g. https://nodejs.org/dist/index.json)
    # to provide real vulnerability verdicts instead of always returning `unknown`.
    set -l node_version $argv[1]
    set -l cache_key $argv[2]

    if curl -fsSL --max-time 5 'https://nodejs.org/en/about/security/' >/dev/null 2>&1
        nvm_cache set "$cache_key" unknown
        echo "ℹ️  Online CVE check is best-effort; verdict unknown for $node_version" >&2
    else
        nvm_cache set "$cache_key" unknown
        echo "ℹ️  Unable to verify security status online" >&2
    end
    return 0
end

function _nvm_security_validate_source -d "Validate version file source"
    set -l source_file $argv[1]

    if not test -f "$source_file"
        echo "⚠️  Source file not found: $source_file" >&2
        return 1
    end

    # Check file permissions: warn if group- or world-writable
    set -l perm (stat -c %a "$source_file" 2>/dev/null; or stat -f %OLp "$source_file" 2>/dev/null)
    if test -n "$perm"
        # Last digit = "other" bits, second-to-last = "group" bits.
        # A bit-2 in either octet means write permission.
        set -l other_digit (string sub -s -1 -- $perm)
        set -l group_digit (string sub -s -2 -l 1 -- $perm)
        # Write bit is set when (digit % 4) >= 2 (covers digits 2, 3, 6, 7).
        if test (math "$other_digit % 4") -ge 2
            echo "⚠️  Insecure permissions on $source_file (world-writable, mode $perm)" >&2
        else if test (math "$group_digit % 4") -ge 2
            echo "⚠️  Insecure permissions on $source_file (group-writable, mode $perm)" >&2
        end
    end

    # Check for suspicious content
    set -l content (string collect < "$source_file")
    if string match -qr '[;&|`$()[\]<>]' "$content"
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
        set -l current_version (node --version 2>/dev/null | string replace -r '^v' '')
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

function _nvm_security_hash -d "Hash a string with the first available hasher"
    set -l input $argv[1]
    if type -q shasum
        echo $input | shasum | cut -d' ' -f1
    else if type -q sha1sum
        echo $input | sha1sum | cut -d' ' -f1
    else if type -q md5sum
        echo $input | md5sum | cut -d' ' -f1
    else
        # Fallback: sanitize input for use as cache key
        echo $input | string replace -ar '[^a-zA-Z0-9]' _
    end
end
