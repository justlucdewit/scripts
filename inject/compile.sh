source "$HOME/scripts/helpers.sh"

# Global list of scripts to compile
scripts_to_compile=(
    "../helpers"
    "requirementCheck"
    "composites/helpers"
    "git_helpers"
    "tmux_helpers"
    "utils"
    "proj"
    "aliases"
    "laravel"
    "local_settings"
    "version_management"
    "vim"
    "work"
    "other"
    "cfind"
    "compile"
    "remotelog"
    "composites/docker/dock"
    "composites/git/gitusers"
    "composites/git/branches"
    "composites/settings/profile"
)

alias lcompile=lsr_compile

print_info "LSR has been loaded in current session"

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
