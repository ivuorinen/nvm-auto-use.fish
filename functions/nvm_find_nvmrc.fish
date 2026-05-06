function nvm_find_nvmrc
    set -l dir (pwd)

    # Validate current directory
    if test -z "$dir"
        return 1
    end

    while test "$dir" != /
        # Check for multiple file formats in order of preference
        for file in .nvmrc .node-version .tool-versions package.json
            set -l file_path "$dir/$file"
            if test -f "$file_path" -a -r "$file_path"
                switch $file
                    case package.json
                        # Extract engines.node field from package.json
                        if command -q jq
                            set -l node_version (jq -r '.engines.node // empty' "$file_path" 2>/dev/null)
                            if test -n "$node_version" -a "$node_version" != null
                                echo "$file_path:engines.node"
                                return 0
                            end
                        end
                    case .tool-versions
                        # Check if .tool-versions contains nodejs entry
                        if grep -q '^nodejs ' "$file_path" 2>/dev/null
                            echo "$file_path:nodejs"
                            return 0
                        end
                    case '*'
                        echo "$file_path"
                        return 0
                end
            end
        end
        set dir (dirname "$dir")
    end

    return 1
end
