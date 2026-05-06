function nvm_project_detect -d "Check if current directory is a Node.js project"
    set -l dir (pwd)

    while test "$dir" != /
        if test -f "$dir/package.json"
            return 0
        end
        set dir (dirname "$dir")
    end

    return 1
end
