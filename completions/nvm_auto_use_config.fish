# Completions for nvm_auto_use_config
complete -c nvm_auto_use_config -f

# Main commands
complete -c nvm_auto_use_config -n "not __fish_seen_subcommand_from auto_install silent debounce exclude include manager reset" -a auto_install -d "Toggle automatic version installation"
complete -c nvm_auto_use_config -n "not __fish_seen_subcommand_from auto_install silent debounce exclude include manager reset" -a silent -d "Toggle silent mode"
complete -c nvm_auto_use_config -n "not __fish_seen_subcommand_from auto_install silent debounce exclude include manager reset" -a debounce -d "Set debounce time in milliseconds"
complete -c nvm_auto_use_config -n "not __fish_seen_subcommand_from auto_install silent debounce exclude include manager reset" -a exclude -d "Add directory pattern to exclusion list"
complete -c nvm_auto_use_config -n "not __fish_seen_subcommand_from auto_install silent debounce exclude include manager reset" -a include -d "Remove directory pattern from exclusion list"
complete -c nvm_auto_use_config -n "not __fish_seen_subcommand_from auto_install silent debounce exclude include manager reset" -a manager -d "Set preferred version manager"
complete -c nvm_auto_use_config -n "not __fish_seen_subcommand_from auto_install silent debounce exclude include manager reset" -a reset -d "Reset all configuration to defaults"

# Boolean options
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from auto_install silent" -a "on enable true 1" -d Enable
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from auto_install silent" -a "off disable false 0" -d Disable

# Manager options
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from manager" -a nvm -d "Use Node Version Manager"
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from manager" -a fnm -d "Use Fast Node Manager"
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from manager" -a volta -d "Use Volta"
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from manager" -a asdf -d "Use asdf"

# Common directory patterns for exclusion
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from exclude" -a node_modules -d "Exclude node_modules directories"
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from exclude" -a ".git" -d "Exclude .git directories"
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from exclude" -a build -d "Exclude build directories"
complete -c nvm_auto_use_config -n "__fish_seen_subcommand_from exclude" -a dist -d "Exclude dist directories"
