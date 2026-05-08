function nvm_auto_use_config -d "Configure nvm-auto-use settings"
    if test (count $argv) -eq 0
        _nvm_auto_use_config_show
        return
    end

    switch $argv[1]
        case auto_install
            _nvm_auto_use_config_auto_install $argv[2]
        case silent
            _nvm_auto_use_config_silent $argv[2]
        case debounce
            _nvm_auto_use_config_debounce $argv[2]
        case exclude
            _nvm_auto_use_config_exclude $argv[2]
        case include
            _nvm_auto_use_config_include $argv[2]
        case manager
            _nvm_auto_use_config_manager $argv[2]
        case project_only
            _nvm_auto_use_config_project_only $argv[2]
        case reset
            _nvm_auto_use_config_reset
        case get
            # Usage: nvm_auto_use_config get [debounce|excluded]
            switch $argv[2]
                case debounce
                    _nvm_auto_use_get_debounce
                case excluded
                    _nvm_auto_use_get_excluded_dirs
                case '*'
                    echo "Usage: nvm_auto_use_config get [debounce|excluded]"
                    return 1
            end
        case '*'
            echo "Usage: nvm_auto_use_config [auto_install|silent|project_only|debounce|exclude|include|manager|reset|get] [value]"
            return 1
    end
end

function _nvm_auto_use_config_show
    echo "nvm-auto-use configuration:"
    echo "  auto_install: "(test -n "$_nvm_auto_use_no_install"; and echo "disabled"; or echo "enabled")
    echo "  silent: "(test -n "$_nvm_auto_use_silent"; and echo "enabled"; or echo "disabled")
    echo "  project_only: "(test -n "$_nvm_auto_use_project_only"; and echo "enabled"; or echo "disabled")
    echo "  debounce_ms: "(_nvm_auto_use_get_debounce)
    echo "  excluded_dirs: "(_nvm_auto_use_get_excluded_dirs)
    echo "  preferred_manager: "(test -n "$_nvm_auto_use_preferred_manager"; and echo "$_nvm_auto_use_preferred_manager"; or echo "auto-detect")
end

function _nvm_auto_use_config_auto_install
    set -l value $argv[1]
    switch $value
        case on enable true 1
            set -e _nvm_auto_use_no_install
            echo "Auto-install enabled"
        case off disable false 0
            set -g _nvm_auto_use_no_install 1
            echo "Auto-install disabled"
        case '*'
            echo "Usage: nvm_auto_use_config auto_install [on|off]"
            return 1
    end
end

function _nvm_auto_use_config_silent
    set -l value $argv[1]
    switch $value
        case on enable true 1
            set -g _nvm_auto_use_silent 1
            echo "Silent mode enabled"
        case off disable false 0
            set -e _nvm_auto_use_silent
            echo "Silent mode disabled"
        case '*'
            echo "Usage: nvm_auto_use_config silent [on|off]"
            return 1
    end
end

function _nvm_auto_use_config_debounce
    set -l value $argv[1]
    if test -n "$value"; and string match -qr '^[0-9]+$' -- "$value"
        set -g _nvm_auto_use_debounce_ms $value
        echo "Debounce set to $value ms"
    else
        echo "Usage: nvm_auto_use_config debounce <milliseconds>"
        return 1
    end
end

function _nvm_auto_use_config_exclude
    set -l value $argv[1]
    if test -n "$value"
        set -g _nvm_auto_use_excluded_dirs $_nvm_auto_use_excluded_dirs $value
        echo "Added $value to excluded directories"
    else
        echo "Usage: nvm_auto_use_config exclude <directory_pattern>"
        return 1
    end
end

function _nvm_auto_use_config_include
    set -l value $argv[1]
    if test -n "$value"
        set -l index (contains -i "$value" $_nvm_auto_use_excluded_dirs)
        if test -n "$index"
            set -e _nvm_auto_use_excluded_dirs[$index]
            echo "Removed $value from excluded directories"
        else
            echo "$value was not in excluded directories"
        end
    else
        echo "Usage: nvm_auto_use_config include <directory_pattern>"
        return 1
    end
end

function _nvm_auto_use_config_project_only
    set -l value $argv[1]
    switch $value
        case on enable true 1
            set -g _nvm_auto_use_project_only 1
            echo "Project-only mode enabled"
        case off disable false 0
            set -e _nvm_auto_use_project_only
            echo "Project-only mode disabled"
        case '*'
            echo "Usage: nvm_auto_use_config project_only [on|off]"
            return 1
    end
end

function _nvm_auto_use_config_manager
    set -l value $argv[1]
    if test -n "$value"
        if contains "$value" nvm fnm volta asdf
            set -g _nvm_auto_use_preferred_manager "$value"
            echo "Preferred manager set to $value"
        else
            echo "Unsupported manager. Supported: nvm, fnm, volta, asdf"
            return 1
        end
    else
        set -e _nvm_auto_use_preferred_manager
        echo "Reset to auto-detect manager"
    end
end

function _nvm_auto_use_config_reset
    set -e _nvm_auto_use_no_install
    set -e _nvm_auto_use_silent
    set -e _nvm_auto_use_project_only
    set -e _nvm_auto_use_debounce_ms
    set -e _nvm_auto_use_excluded_dirs
    set -e _nvm_auto_use_preferred_manager
    echo "Configuration reset to defaults"
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
