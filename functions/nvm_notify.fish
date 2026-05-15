function nvm_notify -a message -d "Send notification for Node.js version changes"
    if test -z "$message"
        return 1
    end

    # Check if notifications are enabled
    if set -q _nvm_auto_use_no_notifications
        return
    end

    # Try different notification methods until one succeeds.
    # AppleScript escaping: backslashes and double quotes must be escaped
    # before embedding in the osascript string, or the script breaks (and a
    # crafted message could escape the literal).
    if command -q osascript
        set -l escaped (string replace -a '\\' '\\\\' -- "$message" \
            | string replace -a '"' '\\"')
        osascript -e "display notification \"$escaped\" with title \"nvm-auto-use\""
        and return 0
    end
    if command -q notify-send
        notify-send nvm-auto-use "$message"
        and return 0
    end
    if command -q terminal-notifier
        terminal-notifier -title nvm-auto-use -message "$message"
        and return 0
    end
    return 1
end
