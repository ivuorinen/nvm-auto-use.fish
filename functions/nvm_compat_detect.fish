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
