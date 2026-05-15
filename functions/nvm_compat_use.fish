function nvm_compat_use -a manager node_version -d "Use specified version with detected manager"
    if test -z "$manager" -o -z "$node_version"
        echo "Usage: nvm_compat_use <manager> <version>" >&2
        return 1
    end

    switch $manager
        case nvm
            nvm use $node_version; or return $status
        case fnm
            fnm use $node_version; or return $status
        case volta
            volta pin node@$node_version; or return $status
        case asdf
            asdf shell nodejs $node_version; or return $status
        case '*'
            echo "Unsupported manager: $manager" >&2
            return 1
    end
end
