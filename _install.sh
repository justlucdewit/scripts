#!/bin/bash

# Script that is responsible for automatically installing
# Lukes script repository on your local machine

# Source the needed helper files
source ~/scripts/helpers.sh

ensure_sudo

# Defining variables of important files and locations
SETTINGS_FILE=~/scripts/_settings.yml
LOCAL_DATA_DIR=~/scripts/local_data
HISTORY_FILE=$LOCAL_DATA_DIR/version_history.yml

# Install needed libraries
if ! install_if_not_exist "yq"; then
    exit 1 # Exit the script with error code
fi

if ! install_if_not_exist "jq"; then
    exit 1 # Exit the script with error code
fi

if ! install_if_not_exist "bc"; then
    exit 1 # Exit the script with error code
fi

if ! install_if_not_exist "silversearcher-ag" "ag"; then
    exit 1 # Exit the script with error code
fi

NAME=$(yq e '.name' $SETTINGS_FILE)
MAJOR_VERSION=$(yq e '.version.major' $SETTINGS_FILE)
MINOR_VERSION=$(yq e '.version.minor' $SETTINGS_FILE)
FULL_VERSION=v$MAJOR_VERSION.$MINOR_VERSION

print_info "Installing $NAME $FULL_VERSION"

# Inject version data into local history file
# create file if not exists, if it does exist:
# check if the current to be installed version is
# newer then the newest in local data
mkdir -p "$LOCAL_DATA_DIR"

# Check if there's already a version file located in the local data dir
if [ -f "$HISTORY_FILE" ]; then
    print_error "There is already a LSR version history present in $LOCAL_DATA_DIR"
    print_error "First run lsr_uninstall to be able to install"
    exit 1
fi

BASHRC_PATH=~/.bashrc
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"

# Check if there is already an injection in bashrc
if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
    print_error "There is already a LSR Loader located in bashrc\nFirst run lsr_uninstall to be able to install"
    print_error "First run lsr_uninstall to be able to install"
    exit 1
fi

# Create version history file if it doesn't exist
if [ ! -f "$HISTORY_FILE" ]; then
    echo "version_history:" > "$HISTORY_FILE"  # Create the YAML structure
    print_info "Created version history file: $HISTORY_FILE"
fi

# Read the current and latest version to be installed
CURRENT_VERSION="$NAME $FULL_VERSION"
LATEST_VERSION=$(yq e '.version_history[-1]' "$HISTORY_FILE" 2>/dev/null)

# Add version to history
echo "  - $CURRENT_VERSION" >> "$HISTORY_FILE"
print_info "Added $CURRENT_VERSION to version history"

# Compile the scripts
if [ -f "$HOME/scripts/build.sh" ]; then
    source "$HOME/scripts/build.sh"
fi

source "$HOME/scripts/inject/compile.sh"
lsr_compile

# Check if the identifier already exists in .bashrc
if ! grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
    # Create a block of code to inject into .bashrc
    INJECTION_CODE="\n\n$BASHRC_STARTER\n$BASHRC_IDENTIFIER\n"
    INJECTION_CODE+="# source \"$HOME/scripts/inject/compile.sh\" # Recompile LSR\n" # Recompile LSR
    INJECTION_CODE+="# lsr_compile\n" # Recompile LSR
    INJECTION_CODE+="source \"$HOME/scripts/build.sh\" # Load LSR in current session\n" # Source the script
    INJECTION_CODE+="$BASHRC_ENDERER"

    # Append the injection code to .bashrc
    echo -e "$INJECTION_CODE" >> "$BASHRC_PATH"
    print_info "Injected script sourcing block into $BASHRC_PATH"
    print_success "Installation of $CURRENT_VERSION was succefull\n"
    print_info "Run 'source ~/.bashrc' to reload, or open a new terminal session"
else
    print_info "Script sourcing block already exists in $BASHRC_PATH"
fi

# Source the updated .bashrc to apply changes
source ~/.bashrc

