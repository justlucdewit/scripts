# Source the needed helper files
source ~/scripts/helpers.sh

BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
SETTINGS_FILE=~/scripts/_settings.yml
HISTORY_FILE=~/scripts/local_data/version_history.yml

alias linstall=lsr_install
alias lreinstall=lsr_reinstall
alias luninstall=lsr_uninstall



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