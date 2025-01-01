source ~/scripts/inject/simple/aliases.sh
source "$HOME/scripts/inject/simple/io_helpers.sh"
source "$HOME/scripts/inject/simple/helpers.sh"

alias lsr="lsr_main_command"

BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
SETTINGS_FILE=~/scripts/_settings.yml
HISTORY_FILE=~/scripts/local_data/version_history.yml

print_logo() {
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
}

lsr_main_command() {
    composite_define_command "lsr"
    composite_define_subcommand "help"
    composite_define_subcommand "status"
    composite_define_subcommand "install"
    composite_define_subcommand "uninstall"
    composite_define_subcommand "reinstall"
    composite_define_subcommand "compile"
    composite_define_subcommand "reload"
    composite_define_subcommand "debug"
    composite_define_subcommand "silence"
    composite_handle_subcommand $@
}


lsr_silence() {
    local SETTINGS_FILE=~/scripts/_settings.yml
    local current_value=$(yq e '.silent' "$SETTINGS_FILE")

    if [[ -n "$1" ]]; then
        # If an argument is passed, set the value based on it
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".silent = $1" "$SETTINGS_FILE"
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
        # No argument passed, toggle the current value
        if [[ "$current_value" == "true" ]]; then
            yq e -i '.silent = false' "$SETTINGS_FILE"
        else
            yq e -i '.silent = true' "$SETTINGS_FILE"
        fi
    fi
}

lsr_help() {
    local output="$(
    local lhelp_file="$HOME/scripts/lhelp.txt"
    
    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line == \#* ]]; then
            printf "$RED%s$RESET\n" "$line"
        else
            printf "%s\n" "$line"
        fi
        
    done < "$lhelp_file"

    print_empty_line)"

    echo "$output" | less --raw-control-chars
}

lsr_debug() {
    local SETTINGS_FILE=~/scripts/_settings.yml
    local current_value=$(yq e '.debug' "$SETTINGS_FILE")

    if [[ -n "$1" ]]; then
        # If an argument is passed, set the value based on it
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".debug = $1" "$SETTINGS_FILE"
            print_info "Debug mode set to $1."
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
        # No argument passed, toggle the current value
        if [[ "$current_value" == "true" ]]; then
            yq e -i '.debug = false' "$SETTINGS_FILE"
            print_info "Debug mode disabled."
        else
            yq e -i '.debug = true' "$SETTINGS_FILE"
            print_info "Debug mode enabled."
        fi
    fi
}

lsr_reload() {
    source ~/.bashrc
    print_success '~/.bashrc reloaded!'
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
    CURRENT_VERSION="$FULL_VERSION"
    CURRENT_BUILD_FILE="build.sh"
    BUILD_FILE_PATH="$HOME/scripts/versions/dev/build.sh"

    # Get the correct build file based on the version and dev setting
    isDev=$(yq e ".dev" "$SETTINGS_FILE")
    isLite=$(yq e ".lite" "$SETTINGS_FILE")
    
    if [[ "$isDev" == "true" ]]; then
        CURRENT_VERSION="dev"
    fi
 
   if [[ "$isLite" == "true" ]]; then
        CURRENT_BUILD_FILE="build-lite.sh"
    fi

    BUILD_FILE_PATH="$HOME/scripts/versions/$CURRENT_VERSION/$CURRENT_BUILD_FILE"

    # Check if there is already an injection in bashrc
    if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        print_error "There is already a LSR Loader located in bashrc\nFirst run lsr_uninstall to be able to install"
        print_error "First run lsr_uninstall to be able to install"
        exit 1
    else
        print_info "Installing LSR $CURRENT_VERSION"
    fi

    if [[ ! -f "$BUILD_FILE_PATH" ]]; then
        if [[ "$isLite" == "true" ]]; then
            print_error "No build found for version $current_version"
        else
            print_error "No build found for version $FULL_VERSION-LITE"
        fi

        exit
    fi
    
    ensure_sudo

    # Install needed libraries
    if ! command_exists "yq"; then
        print_error "Cant install LSR, because yq is not installed"
        exit 1 # Exit the script with error code
    fi

    mkdir -p "$LOCAL_DATA_DIR"

    # Check if the identifier already exists in .bashrc
    if ! grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        # Create a block of code to inject into .bashrc
        INJECTION_CODE="\n\n$BASHRC_STARTER\n$BASHRC_IDENTIFIER\n"
        INJECTION_CODE+="source \"$BUILD_FILE_PATH\" # Load LSR in current session\n" # Source the script
        INJECTION_CODE+="print_info \"LSR $CURRENT_VERSION Has been loaded in current session\"\n" # Source the script
        INJECTION_CODE+="$BASHRC_ENDERER"

        # Append the injection code to .bashrc
        echo -e "$INJECTION_CODE" >> "$BASHRC_PATH"
        print_info "Injected script sourcing block into $BASHRC_PATH"
        print_success "Installation of $CURRENT_VERSION was succefull\n"
        print_info "Run 'source ~/.bashrc' to reload, or open a new terminal session"
    else
        print_info "Script sourcing block already exists in $BASHRC_PATH"
    fi

    lsr_main_command reload
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
    lsr_main_command reload
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
    local version_save_name="$1"
    if [[ $# == 0 ]]; then
        version_save_name="dev"
    fi

    mkdir -p "$HOME/scripts/versions/$version_save_name"

    local build_file="$HOME/scripts/versions/$version_save_name/build.sh"
    local lite_build_file="$HOME/scripts/versions/$version_save_name/build-lite.sh"
    local SETTINGS_FILE=~/scripts/_settings.yml
    local NAME=$(yq e '.name' "$SETTINGS_FILE")
    local MAJOR_VERSION=$(yq e '.version.major' "$SETTINGS_FILE")
    local MINOR_VERSION=$(yq e '.version.minor' "$SETTINGS_FILE")
    local FULL_VERSION=v$MAJOR_VERSION.$MINOR_VERSION
    local SCRIPT_PREFIX="$HOME/scripts/inject/"

    local lite_scripts_to_compile=(
        "simple/helpers"
        "simple/io_helpers"
        "simple/aliases"
        "simple/scripted_fallback"
        "simple/custom_ps1"
        "simple/startup"

        "overwrites/ls"

        "composites/helpers"

        "simple/git_helpers"
        "simple/utils"
        "simple/local_settings"

        "composites/utils/list"
        "composites/utils/obj"
        "composites/development/project"
    )

    local scripts_to_compile=(
        "simple/helpers"
        "simple/requirementCheck" # TODO attempt to make SSH-safe
        "simple/io_helpers"
        "simple/aliases"
        "simple/scripted_fallback"
        "simple/custom_ps1"
        "simple/startup"

        "overwrites/ls"

        "composites/helpers"
        
        "simple/git_helpers" # TODO: make composite
        "tmux_helpers" # TODO: make composite  # TODO attempt to make SSH-safe
        "simple/utils"
        
        "simple/local_settings"
        "work" # TODO: make composite # TODO attempt to make SSH-safe
        "other" # TODO: make composites # TODO attempt to make SSH-safe

        "composites/lsr/lsr" # TODO attempt to make SSH-safe
        "composites/utils/list"
        "composites/utils/obj"
        "composites/docker/dock" # TODO attempt to make SSH-safe
        "composites/git/gitusers" # TODO attempt to make SSH-safe
        "composites/git/gitfeature" # TODO attempt to make SSH-safe
        "composites/git/branches" # TODO attempt to make SSH-safe
        "composites/development/scripts" # TODO attempt to make SSH-safe
        "composites/development/profile" # TODO attempt to make SSH-safe
        "composites/development/goto" # TODO attempt to make SSH-safe
        "composites/development/project"
        "composites/development/wsl" # TODO attempt to make SSH-safe
        "composites/development/notes" # TODO attempt to make SSH-safe
        "composites/system/account" # TODO attempt to make SSH-safe
    )

    # Compile LSR
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
            echo "# - $script.sh" >> "$build_file"  # Add a newline for separation
        else
            print_info "Warning: $script does not exist, skipping."
        fi
    done

    {
        echo "LSR_TYPE=\"LSR-FULL\""
        echo "LSR_VERSION=\"$FULL_VERSION\""
    } >> "$build_file"

    echo "" >> "$build_file"  # Add a newline for separation

    # Loop through the global array and compile the scripts
    print_info "Starting re-compilation of LSR"
    local i=1
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
    print_info "Finished recompiling LSR"

    # Compile LSR-LITE
    if [[ -f "$lite_build_file" ]]; then
        > "$lite_build_file"
    else
        touch "$lite_build_file"
    fi

    {
        echo "# LSR $FULL_VERSION"
        echo "# Local build ($(date +'%H:%M %d/%m/%Y'))"
        echo "# Includes LSR modules:"
    } >> "$lite_build_file"

    for script in "${lite_scripts_to_compile[@]}"; do
        if [[ -f "$SCRIPT_PREFIX$script.sh" ]]; then
            echo "# - $script.sh" >> "$lite_build_file"  # Add a newline for separation
        else
            print_info "Warning: $script does not exist, skipping."
        fi
    done

    {
        echo "LSR_TYPE=\"LSR-LITE\""
        echo "LSR_VERSION=\"$FULL_VERSION\""
    } >> "$lite_build_file"

    echo "" >> "$lite_build_file"  # Add a newline for separation

    print_info "Starting re-compilation of LSR-LITE"
    local i=1
    for script in "${lite_scripts_to_compile[@]}"; do
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
            } >> "$lite_build_file"

            cat "$SCRIPT_PREFIX$script.sh" >> "$lite_build_file"
            echo "" >> "$lite_build_file"  # Add a newline for separation
        fi
    done
    print_info "Finished recompiling LSR-LITE"

    print_empty_line
    print_info "build.sh:      $(get_line_count "$build_file") Lines"
    print_info "build-lite.sh: $(get_line_count "$lite_build_file") Lines"

    print_empty_line
    lsr_main_command reload
}

lsr_version_list() {
        # Define the directory where versions are downloaded
    DOWNLOAD_DIR="/path/to/your/download/location"
    
    echo "LSR versions:"
    # Fetch the versions from the GitHub API
    curl -s https://api.github.com/repos/justlucdewit/scripts/releases | jq -r '.[] | .name' | while read -r version; do
        # Check if the version exists in the download directory
        if [ -f "$HOME/scripts/versions/remote_download_$version/build-full.sh" ]; then
            echo " * $version"  # Add a star if the file exists
        else
            echo "   $version"  # Otherwise, just list the version
        fi
    done
}

lsr_version_download() {
    if [[ "$#" == "0" ]]; then
        print_error "No version given"
        print_error "Usage: lsr version-download <version>"
        return
    fi

    local version="$1"
    print_info "downloading version $version..."

    # Get the download URLs
    local download_url_1=$(curl -s https://api.github.com/repos/justlucdewit/scripts/releases | jq -r ".[] | select(.tag_name == \"$version\") | .assets[0] | .browser_download_url")
    local download_url_2=$(curl -s https://api.github.com/repos/justlucdewit/scripts/releases | jq -r ".[] | select(.tag_name == \"$version\") | .assets[1] | .browser_download_url")

    # No version found
    if [[ "$download_url_1" == "" && "$download_url_2" == "" ]]; then
        print_error "Version $version does not exist"
        return
    fi

    # Download version
    mkdir -p "$HOME/scripts/versions/remote_download_$version"
    wget "$download_url_1" -qO "$HOME/scripts/versions/remote_download_$version/build-lite.sh" >/dev/null
    wget "$download_url_2" -qO "$HOME/scripts/versions/remote_download_$version/build-full.sh" >/dev/null
    print_info "version $version downloaded..."
}
