function nvm_recommendations -d "Smart recommendations for Node.js versions and configurations"
    set -l action $argv[1]

    switch $action
        case suggest_version
            _nvm_recommend_version $argv[2..-1]
        case upgrade_path
            _nvm_recommend_upgrade $argv[2..-1]
        case security_update
            _nvm_recommend_security_update
        case performance
            _nvm_recommend_performance
        case compatibility
            _nvm_recommend_compatibility $argv[2..-1]
        case manager
            _nvm_recommend_manager
        case config
            _nvm_recommend_config
        case '*'
            echo "Usage: nvm_recommendations [suggest_version|upgrade_path|security_update|performance|compatibility|manager|config] [args...]"
            return 1
    end
end

function _nvm_recommend_version -d "Recommend appropriate Node.js version"
    set -l context $argv[1] # 'new_project', 'existing_project', 'migration'

    echo "🔍 Analyzing project for Node.js version recommendation..."

    # Check for existing version constraints
    set -l constraints (_nvm_analyze_version_constraints)
    set -l current_version
    if command -q node
        set current_version (node --version | string replace 'v' '')
    end

    # Get available managers and their capabilities
    set -l available_managers (nvm_compat_detect | string split ' ')

    echo
    echo "📋 Recommendation Analysis:"
    echo "============================"

    # Project type detection
    set -l project_type (_nvm_detect_project_type)
    echo "Project type: $project_type"

    if test -n "$current_version"
        echo "Current version: $current_version"
    end

    if test -n "$constraints"
        echo "Detected constraints: $constraints"
    end

    # Generate recommendations
    echo
    echo "💡 Recommendations:"
    echo "==================="

    switch $context
        case new_project
            _nvm_recommend_for_new_project "$project_type"
        case existing_project
            _nvm_recommend_for_existing_project "$project_type" "$current_version"
        case migration
            _nvm_recommend_for_migration "$current_version"
        case '*'
            _nvm_recommend_general "$project_type" "$current_version"
    end
end

function _nvm_recommend_for_new_project -d "Recommendations for new projects"
    set -l project_type $argv[1]

    switch $project_type
        case react
            echo "• Node.js 18.17.0+ (LTS) - Recommended for React projects"
            echo "• Consider Node.js 20.x for latest features"
            echo "• Avoid odd-numbered versions (development releases)"
        case vue
            echo "• Node.js 16.20.0+ - Minimum for Vue 3"
            echo "• Node.js 18.17.0+ (LTS) - Recommended"
        case angular
            echo "• Node.js 18.13.0+ - Required for Angular 15+"
            echo "• Node.js 18.17.0+ (LTS) - Recommended"
        case nextjs
            echo "• Node.js 18.17.0+ - Required for Next.js 13+"
            echo "• Node.js 20.x for best performance"
        case typescript
            echo "• Node.js 18.17.0+ (LTS) - Excellent TypeScript support"
            echo "• Node.js 20.x for latest TypeScript features"
        case backend
            echo "• Node.js 18.17.0+ (LTS) - Stable for production"
            echo "• Consider Node.js 20.x for performance improvements"
        case '*'
            echo "• Node.js 18.17.0+ (LTS) - Safe choice for most projects"
            echo "• Node.js 20.x for latest features and performance"
    end

    echo
    echo "💭 General Guidelines:"
    echo "• Use LTS versions for production projects"
    echo "• Test with latest version for future compatibility"
    echo "• Pin exact versions in CI/CD environments"
end

function _nvm_recommend_for_existing_project -d "Recommendations for existing projects"
    set -l project_type $argv[1]
    set -l current_version $argv[2]

    if test -z "$current_version"
        echo "• Install Node.js to get version-specific recommendations"
        return
    end

    # Check if current version is LTS
    set -l is_lts (_nvm_check_if_lts "$current_version")
    set -l is_outdated (_nvm_check_if_outdated "$current_version")

    if test "$is_outdated" = true
        echo "⚠️  Current version ($current_version) is outdated"
        echo "• Consider upgrading to latest LTS for security updates"

        # Suggest upgrade path
        set -l upgrade_target (_nvm_suggest_upgrade_target "$current_version")
        if test -n "$upgrade_target"
            echo "• Recommended upgrade: $upgrade_target"
        end
    else if test "$is_lts" = false
        echo "ℹ️  Current version ($current_version) is not LTS"
        echo "• Consider switching to LTS for stability"
    else
        echo "✅ Current version ($current_version) is good"
        echo "• No immediate action needed"
    end

    # Dependency compatibility check
    if test -f "package.json"
        echo
        echo "📦 Dependency Analysis:"
        _nvm_analyze_dependencies
    end
end

function _nvm_recommend_upgrade -d "Recommend upgrade path"
    set -l current_version $argv[1]

    if test -z "$current_version"
        if command -q node
            set current_version (node --version | string replace 'v' '')
        else
            echo "❌ No Node.js version specified or installed"
            return 1
        end
    end

    echo "🔄 Upgrade Path Analysis for Node.js $current_version"
    echo "=================================================="

    # Check for security issues
    nvm_security check_cve "$current_version"
    set -l has_vulnerabilities $status

    if test $has_vulnerabilities -ne 0
        echo
        echo "🚨 SECURITY: Immediate upgrade recommended due to vulnerabilities"
    end

    # Suggest upgrade targets
    set -l major_version (echo "$current_version" | string replace -r '^([0-9]+)\..*' '$1')
    set -l next_lts (_nvm_get_next_lts "$major_version")

    echo
    echo "📈 Upgrade Options:"
    echo "• Patch upgrade: Stay within current minor version"
    echo "• Minor upgrade: Upgrade to latest in major version $major_version"

    if test -n "$next_lts"
        echo "• Major upgrade: Node.js $next_lts (LTS)"
    end

    echo
    echo "🧪 Testing Strategy:"
    echo "1. Test in development environment first"
    echo "2. Run full test suite"
    echo "3. Check for breaking changes in release notes"
    echo "4. Update CI/CD pipelines"
    echo "5. Deploy to staging before production"
end

function _nvm_recommend_security_update -d "Recommend security-focused updates"
    echo "🔒 Security Update Recommendations"
    echo "=================================="

    if command -q node
        set -l current_version (node --version | string replace 'v' '')
        echo "Current version: $current_version"

        # Check for vulnerabilities
        nvm_security check_cve "$current_version"
        set -l has_vulnerabilities $status

        if test $has_vulnerabilities -ne 0
            echo
            echo "🚨 ACTION REQUIRED: Security vulnerabilities found"
            echo "• Upgrade immediately to patch security issues"

            # Suggest secure versions
            set -l secure_versions (_nvm_get_secure_versions)
            if test -n "$secure_versions"
                echo "• Recommended secure versions: $secure_versions"
            end
        else
            echo
            echo "✅ No known vulnerabilities in current version"
            echo "• Keep monitoring for security updates"
        end
    else
        echo "❌ Node.js not installed - cannot assess security status"
    end

    echo
    echo "🛡️  Security Best Practices:"
    echo "• Keep Node.js updated to latest patch versions"
    echo "• Subscribe to Node.js security announcements"
    echo "• Use npm audit for dependency vulnerabilities"
    echo "• Pin specific versions in production"
end

function _nvm_recommend_performance -d "Performance optimization recommendations"
    echo "⚡ Performance Optimization Recommendations"
    echo "=========================================="

    if command -q node
        set -l current_version (node --version | string replace 'v' '')
        set -l major_version (echo "$current_version" | string replace -r '^([0-9]+)\..*' '$1')

        echo "Current version: $current_version"
        echo

        # Version-specific performance notes
        switch $major_version
            case 16
                echo "📈 Upgrade to Node.js 18+ for:"
                echo "• Better V8 engine performance"
                echo "• Improved startup time"
                echo "• Enhanced memory usage"
            case 18
                echo "📈 Consider Node.js 20+ for:"
                echo "• Latest V8 optimizations"
                echo "• Improved module loading"
                echo "• Better async performance"
            case 20 21
                echo "✅ You're using a modern Node.js version"
                echo "• Good performance characteristics"
                echo "• Consider latest patch for micro-optimizations"
            case '*'
                echo "⚠️  Consider upgrading to Node.js 18+ for better performance"
        end
    end

    echo
    echo "🎯 Performance Tips:"
    echo "• Use --max-old-space-size for memory-intensive apps"
    echo "• Enable --experimental-loader for faster imports"
    echo "• Consider --enable-source-maps for better debugging"
    echo "• Profile with --cpu-prof and --heap-prof"
end

function _nvm_detect_project_type -d "Detect project type from files"
    if test -f "package.json"
        set -l deps (cat package.json 2>/dev/null)

        if echo "$deps" | grep -q '"react"'
            echo react
        else if echo "$deps" | grep -q '"vue"'
            echo vue
        else if echo "$deps" | grep -q '"@angular"'
            echo angular
        else if echo "$deps" | grep -q '"next"'
            echo nextjs
        else if echo "$deps" | grep -q '"typescript"'
            echo typescript
        else if echo "$deps" | grep -q '"express"\|"fastify"\|"koa"'
            echo backend
        else
            echo node
        end
    else
        echo general
    end
end

function _nvm_analyze_version_constraints -d "Analyze existing version constraints"
    set -l constraints

    # Check package.json engines
    if test -f "package.json" -a command -q jq
        set -l engine_constraint (jq -r '.engines.node // empty' package.json 2>/dev/null)
        if test -n "$engine_constraint"
            set constraints $constraints "package.json: $engine_constraint"
        end
    end

    # Check .nvmrc
    if test -f ".nvmrc"
        set -l nvmrc_version (cat .nvmrc | string trim)
        set constraints $constraints ".nvmrc: $nvmrc_version"
    end

    echo "$constraints" | string join '; '
end

function _nvm_check_if_lts -d "Check if version is LTS"
    set -l version $argv[1]
    set -l major (echo "$version" | string replace -r '^([0-9]+)\..*' '$1')

    # LTS versions: 16, 18, 20 (even numbers)
    if test (math "$major % 2") -eq 0
        echo true
    else
        echo false
    end
end

function _nvm_check_if_outdated -d "Check if version is outdated"
    set -l version $argv[1]
    set -l major (echo "$version" | string replace -r '^([0-9]+)\..*' '$1')

    # Simplified check - versions below 16 are definitely outdated
    if test $major -lt 16
        echo true
    else
        echo false
    end
end

function _nvm_get_next_lts -d "Get next LTS version"
    set -l current_major $argv[1]
    set -l next_lts

    # Determine next LTS based on current major
    switch $current_major
        case 14 15 16 17
            set next_lts "18.17.0"
        case 18 19
            set next_lts "20.5.0"
        case '*'
            set next_lts "20.5.0"
    end

    echo "$next_lts"
end
