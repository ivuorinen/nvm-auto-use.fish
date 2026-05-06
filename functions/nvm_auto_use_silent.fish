function nvm_auto_use_silent -d "Enable or disable silent mode for nvm-auto-use"
    if test (count $argv) -eq 0
        if set -q _nvm_auto_use_silent
            echo "Silent mode: enabled"
        else
            echo "Silent mode: disabled"
        end
        return
    end

    switch $argv[1]
        case on enable true 1
            set -g _nvm_auto_use_silent 1
            echo "Silent mode enabled"
        case off disable false 0
            set -e -g _nvm_auto_use_silent
            echo "Silent mode disabled"
        case '*'
            echo "Usage: nvm_auto_use_silent [on|off]"
            return 1
    end
end
