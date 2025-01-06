source ~/scripts/inject/simple/aliases.sh
source "$HOME/scripts/inject/simple/io_helpers.sh"
source "$HOME/scripts/inject/simple/helpers.sh"

alias lsr="lsr_main_command"

BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
SETTINGS_FILE=~/scripts/_settings.yml

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

    # Define subcommands
    composite_define_subcommand "docs"
    composite_define_subcommand "compile"
    composite_define_subcommand "disable"
    composite_define_subcommand "debug"
    composite_define_subcommand "silence"

    # Describe subcommands
    composite_define_subcommand_description "docs" "Show documentation of all commands that come with LSR"
    composite_define_subcommand_description "compile" "Compile all the source code into a new version"
    composite_define_subcommand_description "disable" "Disables LSR"
    composite_define_subcommand_description "debug" "Toggles debug mode on/off, allows for special features in LSR"
    composite_define_subcommand_description "silence" "Toggles silent mode on/off, Silents all LSR prints"

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

lsr_docs() {
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

        "simple/auto_env_loader"

        "simple/git_helpers"
        "simple/utils"
        "simple/local_settings"

        "composites/term_app/window"
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
        "simple/auto_env_loader"
        
        "simple/git_helpers" # TODO: make composite
        "tmux_helpers" # TODO: make composite  # TODO attempt to make SSH-safe
        "simple/utils"
        
        "simple/local_settings"
        "work" # TODO: make composite # TODO attempt to make SSH-safe
        "other" # TODO: make composites # TODO attempt to make SSH-safe

        "composites/term_app/window"
        "composites/lsr/lsr" # TODO attempt to make SSH-safe
        "composites/lsr/lsrversion" # TODO attempt to make SSH-safe
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
            print_warn "Warning: $script does not exist, skipping."
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
            print_warn "Warning: $script does not exist, skipping."
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
    exec "$(which bash)" --login
}

lsr_disable() {
    # Check if the LSR loader section exists before attempting to remove it
    if grep -q "^$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        # Remove the LSR loader section from .bashrc
        sed -i "/^$BASHRC_STARTER/,/^$BASHRC_ENDERER/d" "$BASHRC_PATH"
        print_success "Removed LSR loader from $BASHRC_PATH"
    fi
}
