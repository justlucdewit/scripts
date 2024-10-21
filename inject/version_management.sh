# Source the needed helper files
source ~/scripts/helpers.sh

lsr_status() {
    # Define the necessary file paths and identifier
    local BASHRC_PATH=~/.bashrc
    local BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
    local SETTINGS_FILE=~/scripts/_settings.yml
    local HISTORY_FILE=~/scripts/local_data/version_history.yml

    # Variable to store installation status
    bashrc_installed=false
    local_data_installed=false

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

lsr_uninstall() {
    LOCAL_DATA_DIR=~/scripts/local_data
    HISTORY_FILE="$LOCAL_DATA_DIR/version_history.yml"
    BASHRC_PATH=~/.bashrc
    BASHRC_IDENTIFIER="# Luke's Script Repository Loader"

    # Remove version history file if it exists
    if [ -f "$HISTORY_FILE" ]; then
        rm "$HISTORY_FILE"
        print_info "Removed version history file"
    else
        print_info "No version history file found to remove"
    fi

    # Remove injected code from .bashrc
    if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        # Use sed to delete the block starting with the identifier and ending with the next empty line
        sed -i "/$BASHRC_IDENTIFIER/,/^$/d" "$BASHRC_PATH"
        print_info "Removed injected script sourcing block"
    else
        print_info "No injected script sourcing block found"
    fi

    print_success "Succesfully uninstalled Lukes Script Repository"
}