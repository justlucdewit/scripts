# Formating functions for neatly printing info/error/debug messages
print_info() {
    echo -e "\e[34m[info] $1\e[0m"  # \e[34m is the color code for blue
}

print_error() {
    echo -e "\e[31m[error] $1\e[0m"  # \e[31m is the color code for red
}

print_debug() {
    echo -e "\e[33m[debug] $1\e[0m"  # \e[33m is the color code for yellow
}

print_success() {
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
    else
        print_info "Sudo access already available."
    fi
}

# Function to install a command if it doesn't exist
# Uses whatever package manager is available
# suppresses package manager output
# avoids confirmation prompts
install_if_not_exist() {
    local command_name=$1

    if ! command -v "$command_name" &> /dev/null; then
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
        print_info "$command_name is already installed. Skipping installation..."
        return 0  # Indicate success (since the command is already installed)
    fi
}
