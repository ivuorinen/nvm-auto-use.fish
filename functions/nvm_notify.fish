function nvm_notify -a message -d "Send notification for Node.js version changes"
    if test -z "$message"
        return 1
    end

    # Check if notifications are enabled
    if set -q _nvm_auto_use_no_notifications
        return
    end

    # Try different notification methods until one succeeds
    if command -q osascript
        osascript -e "display notification \"$message\" with title \"nvm-auto-use\""
        return
    end
    if command -q notify-send
        notify-send nvm-auto-use "$message"
        return
    end
    if command -q terminal-notifier
        terminal-notifier -title nvm-auto-use -message "$message"
        return
    end
end

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
