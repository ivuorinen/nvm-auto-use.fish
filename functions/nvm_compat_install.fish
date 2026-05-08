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
