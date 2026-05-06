function nvm_notify -a message -d "Send notification for Node.js version changes"
    if test -z "$message"
        return 1
    end

    # Check if notifications are enabled
    if set -q _nvm_auto_use_no_notifications
        return
    end

    # Try different notification methods
    if command -q osascript # macOS
        osascript -e "display notification \"$message\" with title \"nvm-auto-use\""
    else if command -q notify-send # Linux
        notify-send nvm-auto-use "$message"
    else if command -q terminal-notifier # macOS alternative
        terminal-notifier -title nvm-auto-use -message "$message"
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
