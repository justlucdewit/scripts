# Source the needed helper files
source ~/scripts/helpers.sh

BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
SETTINGS_FILE=~/scripts/_settings.yml
HISTORY_FILE=~/scripts/local_data/version_history.yml

alias lstatus=lsr_status
alias linstall=lsr_install
alias lreinstall=lsr_reinstall
alias luninstall=lsr_uninstall

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

lsr_install() {
    ~/scripts/_install.sh
    reload_bash
}

lsr_reinstall() {
    print_info "Uninstalling LSR"
    lsrsilence true
    lsr_uninstall
    lsrsilence false

    print_info "Recompiling LSR"
    lsrsilence true
    lsr_compile
    lsrsilence false

    print_info "Installing LSR"
    lsrsilence true
    lsr_install
    lsrsilence false
}

lsr_uninstall() {
    # 1. Remove the version history file if it exists
    if [[ -f "$HISTORY_FILE" ]]; then
        rm "$HISTORY_FILE"
        print_info "Deleted version history file"
    fi

    # 2. Check if the LSR loader section exists before attempting to remove it
    if grep -q "^$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        # Remove the LSR loader section from .bashrc
        sed -i "/^$BASHRC_STARTER/,/^$BASHRC_ENDERER/d" "$BASHRC_PATH"
        print_info "Removed LSR loader from $BASHRC_PATH"
    fi

    print_empty_line
    print_info "LSR has been reinstalled"
    print_info " - linstall to undo"
    print_info " - Open new session to confirm"
    reload_bash
}