source "$HOME/scripts/helpers.sh"

# Global list of scripts to compile
scripts_to_compile=(
    "compile"
    "definitions"
    "aliases"
    "docker_helpers"
    "git_helpers"
    "laravel"
    "local_settings"
    "proj"
    "tmux_helpers"
    "version_management"
    "vim"
    "work"
    "other"
    # "cfind" # WIP
)

alias lcompile=lsr_compile

lsr_compile() {
    print_info "Starting re-compilation of LSR"
    local build_file=~/scripts/build.sh
    local SETTINGS_FILE=~/scripts/_settings.yml
    local NAME=$(yq e '.name' "$SETTINGS_FILE")
    local MAJOR_VERSION=$(yq e '.version.major' "$SETTINGS_FILE")
    local MINOR_VERSION=$(yq e '.version.minor' "$SETTINGS_FILE")
    local FULL_VERSION=v$MAJOR_VERSION.$MINOR_VERSION
    local SCRIPT_PREFIX="$HOME/scripts/inject/"

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
            print_info " - Compiling $script.sh"
            

            local module_index_line="# Start of LSR module #${i} "
            local module_name_line="# Injected LSR module: $script.sh "
            
            local line_count_line="# Number of lines: $(get_line_count "$SCRIPT_PREFIX$script.sh") "
            local filesize_line="# Filesize: $(get_filesize "$SCRIPT_PREFIX$script.sh") "
            
            

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

    print_info "Finished recompiling LSR at $build_file"
}
