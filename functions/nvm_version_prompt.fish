function nvm_version_prompt -d "Display current Node.js version for prompt integration"
    if command -q node
        set -l node_version (node -v 2>/dev/null | string replace -r '^v' '')
        if test -n "$node_version"
            echo "⬢ $node_version"
        end
    end
end
