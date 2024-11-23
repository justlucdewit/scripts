alias lsr="lsr_main_command"

lsr_main_command() {
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - lsr install"
        echo "  - lsr uninstall"
        echo "  - lsr reinstall"
        echo "  - lsr compile"
        return
    fi

    local command=$1
    shift

    if is_in_list "$command" "status"; then
        lsr_status
    elif is_in_list "$command" "install"; then
        return
    elif is_in_list "$command" "uninstall"; then
        return
    elif is_in_list "$command" "reinstall"; then
        return
    elif is_in_list "$command" "compile"; then
        return
    else
        print_error "Command $command does not exist"
        lsr_main_command # Re-run for help command
    fi
}

lsr_status() {
    # Variable to store installation status
    local bashrc_installed=false
    local local_data_installed=false

    # Check if the identifier exists in .bashrc
    if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        bashrc_installed=true
    fi

    # Check if there's a version history file and if it contains the current version
    if [ -f "$HISTORY_FILE" ]; then
        CURRENT_VERSION=$(yq e '.version_history[-1]' "$HISTORY_FILE" 2>/dev/null)
        if [ ! -z "$CURRENT_VERSION" ]; then
            local_data_installed=true
        fi
    fi

    # Check if both bashrc and version history are present
    if [ "$bashrc_installed" = true ] && [ "$local_data_installed" = true ]; then
        # Retrieve the installed version from _settings.yml
        NAME=$(yq e '.name' "$SETTINGS_FILE")
        MAJOR_VERSION=$(yq e '.version.major' "$SETTINGS_FILE")
        MINOR_VERSION=$(yq e '.version.minor' "$SETTINGS_FILE")
        FULL_VERSION="v$MAJOR_VERSION.$MINOR_VERSION"

        print_success "$NAME $FULL_VERSION is installed."
    else
        print_error "Lukes Script Repository is not installed."
    fi
}