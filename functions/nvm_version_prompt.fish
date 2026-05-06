function nvm_version_prompt -d "Display current Node.js version for prompt integration"
    if command -q node
        set -l version (node -v 2>/dev/null | string replace 'v' '')
        if test -n "$version"
            echo "⬢ $version"
        end
    end
end

function nvm_version_status -d "Show detailed Node.js version status"
    if command -q node
        set -l version (node -v 2>/dev/null | string replace -r '^v' '')
        set -l npm_version
        if command -q npm
            set npm_version (npm -v 2>/dev/null)
        end

        echo "Node.js: v$version"
        if test -n "$npm_version"
            echo "npm: v$npm_version"
        end

        if set -q _nvm_auto_use_cached_file
            echo "Auto-use: $_nvm_auto_use_cached_file"
        end
    else
        echo "Node.js: not installed"
    end
end
