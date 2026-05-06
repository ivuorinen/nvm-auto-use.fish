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

    if command -q asdf; and test -f ~/.tool-versions
        if grep -q nodejs ~/.tool-versions 2>/dev/null
            set managers $managers asdf
        end
    end

    if test (count $managers) -eq 0
        echo "No supported Node.js version managers found"
        return 1
    end

    echo "Available managers:" (string join ", " $managers)
    echo $managers
end

function nvm_compat_use -a manager version -d "Use specified version with detected manager"
    if test -z "$manager" -o -z "$version"
        echo "Usage: nvm_compat_use <manager> <version>"
        return 1
    end

    switch $manager
        case nvm
            nvm use $version
        case fnm
            fnm use $version
        case volta
            volta pin node@$version
        case asdf
            asdf local nodejs $version
        case '*'
            echo "Unsupported manager: $manager"
            return 1
    end
end

function nvm_compat_install -a manager version -d "Install specified version with detected manager"
    if test -z "$manager" -o -z "$version"
        echo "Usage: nvm_compat_install <manager> <version>"
        return 1
    end

    switch $manager
        case nvm
            nvm install $version
        case fnm
            fnm install $version
        case volta
            volta install node@$version
        case asdf
            asdf install nodejs $version
        case '*'
            echo "Unsupported manager: $manager"
            return 1
    end
end
