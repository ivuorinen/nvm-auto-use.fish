function nvm_auto_use_config -d "Configure nvm-auto-use settings"
    if test (count $argv) -eq 0
        echo "nvm-auto-use configuration:"
        echo "  auto_install: "(test -n "$_nvm_auto_use_no_install"; and echo "disabled"; or echo "enabled")
        echo "  silent: "(test -n "$_nvm_auto_use_silent"; and echo "enabled"; or echo "disabled")
        echo "  debounce_ms: "(_nvm_auto_use_get_debounce)
        echo "  excluded_dirs: "(_nvm_auto_use_get_excluded_dirs)
        echo "  preferred_manager: "(test -n "$_nvm_auto_use_preferred_manager"; and echo "$_nvm_auto_use_preferred_manager"; or echo "auto-detect")
        return
    end

    switch $argv[1]
        case auto_install
            switch $argv[2]
                case on enable true 1
                    set -e _nvm_auto_use_no_install
                    echo "Auto-install enabled"
                case off disable false 0
                    set -g _nvm_auto_use_no_install 1
                    echo "Auto-install disabled"
                case '*'
                    echo "Usage: nvm_auto_use_config auto_install [on|off]"
            end
        case silent
            switch $argv[2]
                case on enable true 1
                    set -g _nvm_auto_use_silent 1
                    echo "Silent mode enabled"
                case off disable false 0
                    set -e _nvm_auto_use_silent
                    echo "Silent mode disabled"
                case '*'
                    echo "Usage: nvm_auto_use_config silent [on|off]"
            end
        case debounce
            if test -n "$argv[2]" -a (string match -r '^[0-9]+$' "$argv[2]")
                set -g _nvm_auto_use_debounce_ms $argv[2]
                echo "Debounce set to $argv[2]ms"
            else
                echo "Usage: nvm_auto_use_config debounce <milliseconds>"
            end
        case exclude
            if test -n "$argv[2]"
                set -g _nvm_auto_use_excluded_dirs $_nvm_auto_use_excluded_dirs $argv[2]
                echo "Added $argv[2] to excluded directories"
            else
                echo "Usage: nvm_auto_use_config exclude <directory_pattern>"
            end
        case include
            if test -n "$argv[2]"
                set -l index (contains -i "$argv[2]" $_nvm_auto_use_excluded_dirs)
                if test -n "$index"
                    set -e _nvm_auto_use_excluded_dirs[$index]
                    echo "Removed $argv[2] from excluded directories"
                else
                    echo "$argv[2] was not in excluded directories"
                end
            else
                echo "Usage: nvm_auto_use_config include <directory_pattern>"
            end
        case manager
            if test -n "$argv[2]"
                if contains "$argv[2]" nvm fnm volta asdf
                    set -g _nvm_auto_use_preferred_manager "$argv[2]"
                    echo "Preferred manager set to $argv[2]"
                else
                    echo "Unsupported manager. Supported: nvm, fnm, volta, asdf"
                end
            else
                set -e _nvm_auto_use_preferred_manager
                echo "Reset to auto-detect manager"
            end
        case reset
            set -e _nvm_auto_use_no_install
            set -e _nvm_auto_use_silent
            set -e _nvm_auto_use_debounce_ms
            set -e _nvm_auto_use_excluded_dirs
            set -e _nvm_auto_use_preferred_manager
            echo "Configuration reset to defaults"
        case '*'
            echo "Usage: nvm_auto_use_config [auto_install|silent|debounce|exclude|include|manager|reset] [value]"
            return 1
    end
end

function _nvm_auto_use_get_debounce
    if test -n "$_nvm_auto_use_debounce_ms"
        echo "$_nvm_auto_use_debounce_ms"
    else
        echo 500
    end
end

function _nvm_auto_use_get_excluded_dirs
    if test -n "$_nvm_auto_use_excluded_dirs"
        string join ', ' $_nvm_auto_use_excluded_dirs
    else
        echo "node_modules, .git"
    end
end
