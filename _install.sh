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

# Create version history file if it doesn't exist
if [ ! -f "$HISTORY_FILE" ]; then
    echo "version_history:" > "$HISTORY_FILE"  # Create the YAML structure
    print_info "Created version history file: $HISTORY_FILE"
fi

# Read the current and latest version to be installed
CURRENT_VERSION="$NAME $FULL_VERSION"
LATEST_VERSION=$(yq e '.version_history[-1]' "$HISTORY_FILE" 2>/dev/null)

# Check if there's a latest version and add it to history
if [ -z "$LATEST_VERSION" ]; then
    echo "  - $CURRENT_VERSION" >> "$HISTORY_FILE"
    print_info "Added $CURRENT_VERSION to history"
else
    print_error "$NAME is already intalled"
    exit 1
fi

BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"

# Read the list of scripts to ignore
IGNORE_SCRIPTS=$(yq e '.dont_source_scripts[]' "$SETTINGS_FILE" | tr '\n' ' ')

# Check if the identifier already exists in .bashrc
if ! grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
    # Create a block of code to inject into .bashrc
    INJECTION_CODE="\n\n$BASHRC_IDENTIFIER\n"
    INJECTION_CODE+="echo -e \"\e[34m[info] Initializing Lukes Script Repository:\e[0m\"\n"
    INJECTION_CODE+="for i in \$HOME/scripts/inject/*.sh\n"
    INJECTION_CODE+="do\n"
    INJECTION_CODE+="    if [[ ! \$(basename \"\$i\") =~ ^(${IGNORE_SCRIPTS// /|})\$ ]]; then\n"
    INJECTION_CODE+="        echo -e \"\e[34m[info]     Loading script: \$(basename \"\$i\")\e[0m\"\n"
    INJECTION_CODE+="        source \"\$i\"\n"
    INJECTION_CODE+="    fi\n"
    INJECTION_CODE+="done\n"

    # Append the injection code to .bashrc
    echo -e "$INJECTION_CODE" >> "$BASHRC_PATH"
    print_info "Injected script sourcing block into $BASHRC_PATH"
else
    print_info "Script sourcing block already exists in $BASHRC_PATH"
fi

print_success "Installation of $CURRENT_VERSION was succefull"

echo ""

# Source the updated .bashrc to apply changes
source ~/.bashrc

