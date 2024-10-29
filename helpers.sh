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

# Formating functions for neatly printing info/error/debug messages
print_info() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[34m[info] $1\e[0m"  # \e[34m is the color code for blue
}

print_normal() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo "$1"
}

print_empty_line() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo ""
}

print_error() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[31m[error] $1\e[0m"  # \e[31m is the color code for red
}

print_debug() {
    SETTINGS_FILE=~/scripts/_settings.yml
    DEBUG=$(yq e '.debug' "$SETTINGS_FILE")
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $DEBUG == true || $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[33m[debug] $1\e[0m"  # \e[33m is the color code for yellow
}

print_success() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[32m[success] $1\e[0m"  # \e[32m is the color code for green
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

# Function to install a command if it doesn't exist
# Uses whatever package manager is available
# suppresses package manager output
# avoids confirmation prompts
install_if_not_exist() {
    local command_name=$1
    local test_command_name=$2

    if [[ -z $test_command_name ]]; then
        test_command_name=$command_name
    fi

    if ! command -v "$test_command_name" &> /dev/null; then
        print_info "$command_name is not installed. Attempting to install..."

        # Detect package manager and install command
        if command -v apt-get &> /dev/null; then
            print_info "Attempting to install $command_name with apt-get..."
            sudo add-apt-repository ppa:rmescandon/yq -y > /dev/null 2>&1
            sudo apt-get update > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                print_error "Failed to update package list with apt-get."
                return 1  # Indicate failure
            fi
            sudo apt-get install -y "$command_name" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                print_error "Failed to install $command_name using apt-get."
                return 1  # Indicate failure
            fi

        elif command -v yum &> /dev/null; then
            print_info "Attempting to install $command_name with yum..."
            sudo yum install -y "$command_name" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                print_error "Failed to install $command_name using yum."
                return 1  # Indicate failure
            fi

        elif command -v dnf &> /dev/null; then
            print_info "Attempting to install $command_name with dnf..."
            sudo dnf install -y "$command_name" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                print_error "Failed to install $command_name using dnf."
                return 1  # Indicate failure
            fi

        elif command -v brew &> /dev/null; then
            print_info "Attempting to install $command_name with brew..."
            sudo brew install "$command_name" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                print_error "Failed to install $command_name using brew."
                return 1  # Indicate failure
            fi

        elif command -v pacman &> /dev/null; then
            print_info "Attempting to install $command_name with pacman..."
            sudo pacman -S --noconfirm "$command_name" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                print_error "Failed to install $command_name using pacman."
                return 1  # Indicate failure
            fi

        else
            print_info "No supported package manager found. Attempting to download $command_name directly..."
            case "$command_name" in
                yq)
                    curl -L -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 > /dev/null 2>&1
                    if [ $? -ne 0 ]; then
                        print_error "Failed to download yq."
                        return 1  # Indicate failure
                    fi
                    chmod +x /usr/local/bin/yq
                    if [ $? -ne 0 ]; then
                        print_error "Failed to set execute permissions for yq."
                        return 1  # Indicate failure
                    fi
                    ;;
                # Add more commands here if needed
                *)
                    print_info "Unsupported command: $command_name. Please install it manually."
                    return 1  # Indicate failure
                    ;;
            esac
        fi

        print_info "$command_name has been installed successfully."
        return 0  # Indicate success
    else
        return 0  # Indicate success (since the command is already installed)
    fi
}
