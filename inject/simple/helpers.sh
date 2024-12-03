enable_lsr_silence() {
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        print_error "enable_lsr_silence is LSR-FULL only"
        exit
    fi

    SETTINGS_FILE=~/scripts/_settings.yml
    yq e -i '.silent=true' "$SETTINGS_FILE"
}

disable_lsr_silence() {
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        print_error "disable_lsr_silence is LSR-FULL only"
        exit
    fi

    SETTINGS_FILE=~/scripts/_settings.yml
    yq e -i '.silent=false' "$SETTINGS_FILE"
}

is_in_list() {
    local value="$1"
    local list="$2"

    if [[ ",$list," =~ ",$value," ]]; then
        return 0  # Found
    else
        return 1  # Not found
    fi
}

prompt_if_not_exists() {
    local prompt_message="$1"  # The prompt message
    local value="$2"            # The value to check (passed as the second argument)

    if [ -z "$value" ]; then  # Check if the value is empty
        read -p "$prompt_message: " user_input
        echo "$user_input"     # Return the user input
    else
        echo "$value"          # Return the existing value
    fi
}

get_filesize() {
    local file="$1"

    if [[ -f "$file" ]]; then
        local size_bytes=$(stat --format="%s" "$file")

        if [[ $size_bytes -lt 1024 ]]; then
            echo "${size_bytes} B"
        elif [[ $size_bytes -lt 1048576 ]]; then
            echo "$(bc <<< "scale=2; $size_bytes/1024") KB"
        elif [[ $size_bytes -lt 1073741824 ]]; then
            echo "$(bc <<< "scale=2; $size_bytes/1048576") MB"
        else
            echo "$(bc <<< "scale=2; $size_bytes/1073741824") GB"
        fi
    else
        echo "File does not exist."
    fi
}

get_line_count() {
    local file="$1"

    if [[ -f "$file" ]]; then
        wc -l < "$file"
    else
        echo "File does not exist."
    fi
}

# Function to ensure the user has sudo privileges
# and prompts for password if needed
ensure_sudo() {
    # Check if the user can run sudo commands
    if ! sudo -l &> /dev/null; then
        print_info "Requesting sudo access..."
        
        # Prompt for password to obtain sudo access
        sudo -v
        if [ $? -ne 0 ]; then
            print_error "This script requires sudo privileges. Please run with sudo."
            exit 1  # Exit if the user does not have sudo privileges
        fi

        print_info "Sudo access granted."
    fi
}

reset_ifs() {
    IFS=$'\ \t\n'
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

requires_package() {
    local packageName=$1
    local requireScope=$2

    if ! command_exists "$packageName"; then
        print_warn "Package '$packageName' is required in order to use $requireScope"
    fi
}
