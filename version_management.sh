# Source the needed helper files
source ~/scripts/helpers.sh

uninstall() {
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