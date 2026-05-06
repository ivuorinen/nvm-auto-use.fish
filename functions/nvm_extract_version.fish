function nvm_extract_version -a file_path -d "Extract Node.js version from various file formats"
    if test -z "$file_path"
        return 1
    end

    set -l file_name (basename "$file_path")
    set -l version_info (string split ':' "$file_path")
    set -l actual_file $version_info[1]
    set -l format $version_info[2]

    if not test -f "$actual_file" -a -r "$actual_file"
        return 1
    end

    switch "$format"
        case engines.node
            # Extract from package.json engines.node field
            if command -q jq
                set -l node_version (jq -r '.engines.node // empty' "$actual_file" 2>/dev/null)
                if test -n "$node_version" -a "$node_version" != null
                    # Handle version ranges - extract first valid version
                    set node_version (string replace -r '^[^0-9]*([0-9]+\.?[0-9]*\.?[0-9]*).*' '$1' "$node_version")
                    echo "$node_version"
                    return 0
                end
            end
        case nodejs
            # Extract from .tool-versions nodejs line
            set -l node_version (grep '^nodejs ' "$actual_file" | cut -d' ' -f2 | string trim)
            if test -n "$node_version"
                echo "$node_version"
                return 0
            end
        case '*'
            # Standard .nvmrc or .node-version file
            set -l node_version (cat "$actual_file" | string trim)
            if test -n "$node_version"
                # Strip leading 'v'
                set node_version (string replace -r '^v' '' "$node_version")
                # Handle nvm aliases
                switch "$node_version"
                    case 'lts/*' lts latest stable node
                        if command -q nvm
                            set node_version (nvm version-remote "$node_version" 2>/dev/null | string replace -r '^v' '')
                        else if command -q node
                            set node_version (node -v 2>/dev/null | string replace -r '^v' '')
                        end
                end
                echo "$node_version"
                return 0
            end
    end

    return 1
end
