source ~/scripts/helpers.sh
source ~/scripts/inject/aliases.sh

alias lsr="lsr_main_command"

BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
SETTINGS_FILE=~/scripts/_settings.yml
HISTORY_FILE=~/scripts/local_data/version_history.yml

lsr_main_command() {
    print_normal ""
    print_normal "▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓"
    print_normal "▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓"
    print_normal "▓▓▓▓  ▓▓▓▓              ▓▓▓▓  ▓▓▓▓"
    print_normal "▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓  ▓▓▓▓"
    print_normal "▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓      "
    print_normal "▓▓▓▓              ▓▓▓▓  ▓▓▓▓      "
    print_normal "▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓      "
    print_normal "▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓      "
    print_normal ""

    if [ ! "$#" -gt 0 ]; then
        print_normal "usage: "
        print_normal "  - lsr status"
        print_normal "  - lsr install"
        print_normal "  - lsr uninstall" # Todo
        print_normal "  - lsr reinstall" # Todo
        print_normal "  - lsr compile"
        return
    fi

    local command=$1
    shift

    if is_in_list "$command" "status"; then
        lsr_status
    elif is_in_list "$command" "install"; then
        ensure_sudo
        lsr_install
    elif is_in_list "$command" "uninstall"; then
        lsr_uninstall
    elif is_in_list "$command" "reinstall"; then
        lsr_reinstall
    elif is_in_list "$command" "compile"; then
        lsr_compile
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

    # Check if both bashrc and version history are present
    if [ "$bashrc_installed" = true ]; then
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
    # Defining variables of important files and locations
    SETTINGS_FILE=~/scripts/_settings.yml
    LOCAL_DATA_DIR=~/scripts/local_data
    NAME=$(yq e '.name' $SETTINGS_FILE)
    MAJOR_VERSION=$(yq e '.version.major' $SETTINGS_FILE)
    MINOR_VERSION=$(yq e '.version.minor' $SETTINGS_FILE)
    FULL_VERSION=v$MAJOR_VERSION.$MINOR_VERSION
    BASHRC_PATH=~/.bashrc
    BASHRC_STARTER="# !! LSR LOADER START !!"
    BASHRC_ENDERER="# !! LSR LOADER END !!"
    BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
    CURRENT_VERSION="$NAME $FULL_VERSION"

    # Check if there is already an injection in bashrc
    if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        print_error "There is already a LSR Loader located in bashrc\nFirst run lsr_uninstall to be able to install"
        print_error "First run lsr_uninstall to be able to install"
        exit 1
    else
        print_info "Installing $CURRENT_VERSION"
    fi
    
    ensure_sudo

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

    mkdir -p "$LOCAL_DATA_DIR"

    # Check if the identifier already exists in .bashrc
    if ! grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        # Create a block of code to inject into .bashrc
        INJECTION_CODE="\n\n$BASHRC_STARTER\n$BASHRC_IDENTIFIER\n"
        INJECTION_CODE+="# source \"$HOME/scripts/inject/compile.sh\" # Recompile LSR\n" # Recompile LSR
        INJECTION_CODE+="# lsr_compile\n" # Recompile LSR
        INJECTION_CODE+="source \"$HOME/scripts/build.sh\" # Load LSR in current session\n" # Source the script
        INJECTION_CODE+="print_info \"LSR Has been loaded in current session\"" # Source the script
        INJECTION_CODE+="$BASHRC_ENDERER"

        # Append the injection code to .bashrc
        echo -e "$INJECTION_CODE" >> "$BASHRC_PATH"
        print_info "Injected script sourcing block into $BASHRC_PATH"
        print_success "Installation of $CURRENT_VERSION was succefull\n"
        print_info "Run 'source ~/.bashrc' to reload, or open a new terminal session"
    else
        print_info "Script sourcing block already exists in $BASHRC_PATH"
    fi

    reload_bash
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

lsr_compile() {
    print_info "Starting re-compilation of LSR"
    local build_file="$HOME/scripts/build.sh"
    local minimized_build_file="$HOME/scripts/build.min.sh"
    local SETTINGS_FILE=~/scripts/_settings.yml
    local NAME=$(yq e '.name' "$SETTINGS_FILE")
    local MAJOR_VERSION=$(yq e '.version.major' "$SETTINGS_FILE")
    local MINOR_VERSION=$(yq e '.version.minor' "$SETTINGS_FILE")
    local FULL_VERSION=v$MAJOR_VERSION.$MINOR_VERSION
    local SCRIPT_PREFIX="$HOME/scripts/inject/"
    local scripts_to_compile=(
        "../helpers"
        "requirementCheck"
        "startup"
        "composites/helpers"
        "git_helpers"
        "tmux_helpers"
        "utils"
        "proj"
        "aliases"
        "local_settings"
        "vim"
        "work"
        "other"
        "cfind"
        "remotelog"
        "composites/lsr/lsr"
        "composites/utils/list"
        "composites/docker/dock"
        "composites/git/gitusers"
        "composites/git/branches"
        "composites/settings/profile"
    )

    # Make buildfile if it doesn't exist, else clear it
    if [[ -f "$build_file" ]]; then
        > "$build_file"
    else
        touch "$build_file"
    fi

    {
        echo "# LSR $FULL_VERSION"
        echo "# Local build ($(date +'%H:%M %d/%m/%Y'))"
        echo "# Includes LSR modules:"
    } >> "$build_file"

    for script in "${scripts_to_compile[@]}"; do
        if [[ -f "$SCRIPT_PREFIX$script.sh" ]]; then
            echo "# - $SCRIPT_PREFIX$script.sh" >> "$build_file"  # Add a newline for separation
        else
            print_info "Warning: $script does not exist, skipping."
        fi
    done

    echo "" >> "$build_file"  # Add a newline for separation

    local i=1

    # Loop through the global array and compile the scripts
    for script in "${scripts_to_compile[@]}"; do
        if [[ -f "$SCRIPT_PREFIX$script.sh" ]]; then
            local script_line_count=$(get_line_count "$SCRIPT_PREFIX$script.sh")
            local script_filesize=$(get_filesize "$SCRIPT_PREFIX$script.sh")
            print_info " - Compiling $script.sh ($script_filesize/$script_line_count lines)"
            
            local module_index_line="# Start of LSR module #${i} "
            ((i++))
            local module_name_line="# Injected LSR module: $script.sh "
            
            local line_count_line="# Number of lines: $script_line_count "
            local filesize_line="# Filesize: $script_filesize "
            
            # Function to calculate the length of a string
            get_length() {
                echo "${#1}"
            }

            # Determine the maximum length of the content (excluding hashtags)
            max_content_length=$(get_length "$module_index_line")
            for line in "$module_name_line" "$line_count_line" "$filesize_line"; do
                line_length=$(get_length "$line")
                if [[ $line_length -gt $max_content_length ]]; then
                    max_content_length=$line_length
                fi
            done

            # Add space for the right-side hashtag
            max_line_length=$((max_content_length + 2)) # +2 for the hashtags on each side

            # Make a horizontal line exactly long enough
            horizontal_line=$(printf "#%0.s" $(seq 1 $max_line_length))

            # Function to pad the lines with spaces and add the right border hashtag
            pad_line() {
                local content="$1"
                local padding_needed=$((max_line_length - $(get_length "$content") - 1)) # -1 for the ending hashtag
                printf "%s%${padding_needed}s#" "$content" ""
            }

            {
                echo "$horizontal_line"
                echo "$(pad_line "$module_index_line")"
                echo "$(pad_line "$module_name_line")"
                echo "$(pad_line "$line_count_line")"
                echo "$(pad_line "$filesize_line")"
                echo "$horizontal_line"
            } >> "$build_file"

            cat "$SCRIPT_PREFIX$script.sh" >> "$build_file"
            echo "" >> "$build_file"  # Add a newline for separation
        fi
    done

    $build_file_size

    print_info "Finished recompiling LSR at $build_file"
    print_info "Total final build.sh size: $(get_filesize "$build_file")"
    print_info "Total final build.sh lines: $(get_line_count "$build_file")"

    # Minimization
    print_empty_line
    print_info "Generating minimized build file"

    local remove_comment_lines='^\s*#'  # Matches lines that are just comments
    local trim_whitespace='^\s*|\s*$'   # Matches leading and trailing whitespace on each line
    local remove_empty_lines='^$'       # Matches empty lines
    
    # Check if minified file exists, if not, create it
    if [[ ! -f $minimized_build_file ]]; then
        touch "$minimized_build_file"
    fi

    # Copy original script to the minified script file
    cp "$build_file" "$minimized_build_file"

    # Apply regex transformations one by one
    sed -i "/$remove_comment_lines/d" "$minimized_build_file"
    sed -i "s/$trim_whitespace//g" "$minimized_build_file"
    sed -i "/$remove_empty_lines/d" "$minimized_build_file"

    print_info "Total final build.min.sh size: $(get_filesize "$minimized_build_file")"
    print_info "Total final build.min.sh lines: $(get_line_count "$minimized_build_file")"

    reload_bash
}