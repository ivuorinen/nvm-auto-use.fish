function nvm_compat_detect -d "Detect available Node.js version managers"
    set -l managers

    if command -q nvm
        set managers $managers nvm
    end

    if command -q fnm
        set managers $managers fnm
    end

    if command -q volta
        set managers $managers volta
    end

    # asdf manages many runtimes; only include it when the nodejs plugin
    # is actually installed — checking ~/.tool-versions misses project-local
    # setups (.tool-versions in a subdirectory).
    if command -q asdf; and asdf plugin list 2>/dev/null | grep -qx nodejs
        set managers $managers asdf
    end

    if test (count $managers) -eq 0
        return 1
    end

    echo $managers
end

function nvm_compat_use -a manager node_version -d "Use specified version with detected manager"
    if test -z "$manager" -o -z "$node_version"
        echo "Usage: nvm_compat_use <manager> <version>"
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
            asdf local nodejs $node_version; or return $status
        case '*'
            echo "Unsupported manager: $manager"
            return 1
    end
end

function nvm_compat_install -a manager node_version -d "Install specified version with detected manager"
    if test -z "$manager" -o -z "$node_version"
        echo "Usage: nvm_compat_install <manager> <version>"
        return 1
    end

    switch $manager
        case nvm
            nvm install $node_version; or return $status
        case fnm
            fnm install $node_version; or return $status
        case volta
            volta install node@$node_version; or return $status
        case asdf
            asdf install nodejs $node_version; or return $status
        case '*'
            echo "Unsupported manager: $manager"
            return 1
    end
end
