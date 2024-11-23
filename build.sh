# LSR v1.1
# Local build (12:09 23/11/2024)
# Includes LSR modules:
# - /home/lucdewit/scripts/inject/../helpers.sh
# - /home/lucdewit/scripts/inject/requirementCheck.sh
# - /home/lucdewit/scripts/inject/startup.sh
# - /home/lucdewit/scripts/inject/composites/helpers.sh
# - /home/lucdewit/scripts/inject/git_helpers.sh
# - /home/lucdewit/scripts/inject/tmux_helpers.sh
# - /home/lucdewit/scripts/inject/utils.sh
# - /home/lucdewit/scripts/inject/proj.sh
# - /home/lucdewit/scripts/inject/aliases.sh
# - /home/lucdewit/scripts/inject/laravel.sh
# - /home/lucdewit/scripts/inject/local_settings.sh
# - /home/lucdewit/scripts/inject/version_management.sh
# - /home/lucdewit/scripts/inject/vim.sh
# - /home/lucdewit/scripts/inject/work.sh
# - /home/lucdewit/scripts/inject/other.sh
# - /home/lucdewit/scripts/inject/cfind.sh
# - /home/lucdewit/scripts/inject/compile.sh
# - /home/lucdewit/scripts/inject/remotelog.sh
# - /home/lucdewit/scripts/inject/composites/lsr/lsr.sh
# - /home/lucdewit/scripts/inject/composites/utils/list.sh
# - /home/lucdewit/scripts/inject/composites/docker/dock.sh
# - /home/lucdewit/scripts/inject/composites/git/gitusers.sh
# - /home/lucdewit/scripts/inject/composites/git/branches.sh
# - /home/lucdewit/scripts/inject/composites/settings/profile.sh

#######################################
# Start of LSR module #1              #
# Injected LSR module: ../helpers.sh  #
# Number of lines: 312                #
# Filesize: 8.86 KB                   #
#######################################
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

print_warn() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[33m[warn] $1\e[0m"  # \e[34m is the color code for blue
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

read_info() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -ne "\e[34m[info] $1\e[0m"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}

read_normal() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -n "$1"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}

read_error() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -ne "\e[31m[error] $1\e[0m"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}

read_debug() {
    SETTINGS_FILE=~/scripts/_settings.yml
    DEBUG=$(yq e '.debug' "$SETTINGS_FILE")
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $DEBUG == true || $SILENT == true ]]; then
        return 0
    fi

    echo -ne "\e[33m[debug] $1\e[0m"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}

read_success() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -ne "\e[32m[success] $1\e[0m"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
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

#############################################
# Start of LSR module #2                    #
# Injected LSR module: requirementCheck.sh  #
# Number of lines: 6                        #
# Filesize: 307 B                           #
#############################################
# This file includes require package statements that makes sure that all packages needed for a basic LSR
# installation are indeed correctly installed and callable
requires_package "yq" "LSR"
requires_package "jq" "LSR"
requires_package "node" "LSR"
requires_package "npm" "LSR"
requires_package "git" "LSR"
####################################
# Start of LSR module #3           #
# Injected LSR module: startup.sh  #
# Number of lines: 20              #
# Filesize: 577 B                  #
####################################
# Inject the LSR gitconfig in the global gitconfig
CUSTOM_CONFIG="$HOME/scripts/extra_config_files/lsr.gitconfig"
GLOBAL_CONFIG="$HOME/.gitconfig"

if [ ! -f "$GLOBAL_CONFIG" ]; then
    touch "$GLOBAL_CONFIG"
fi

if ! grep -q "$CUSTOM_CONFIG" "$GLOBAL_CONFIG"; then
    echo -e "\n[include]\n\tpath = $CUSTOM_CONFIG" >> "$GLOBAL_CONFIG"
fi

# Inject the LSR global gitignore
GLOBAL_GITIGNORE="$HOME/scripts/extra_config_files/lsr.gitignore"
if ! grep -q "lsr.gitignore" "$GLOBAL_CONFIG"; then
    cat <<EOL >> $GLOBAL_CONFIG
[core]
    excludesfile = $GLOBAL_GITIGNORE
EOL

fi
###############################################
# Start of LSR module #4                      #
# Injected LSR module: composites/helpers.sh  #
# Number of lines: 129                        #
# Filesize: 3.36 KB                           #
###############################################
composite_help_get_flags() {
    reset_ifs
    local flags=()

    # Split the remaining arguments into flags (starts with --)
    for arg in "$@"; do
        if [[ "$arg" == *"="* ]]; then
            flagName="${arg%%=*}"  # Everything before the first '='
            value="${arg#*=}"      # Everything after the first '='
            arg="$flagName=\"$value\""
        fi

        if [[ "$arg" =~ ^-- ]]; then
            flags+=("$arg")
        elif [[ "$arg" =~ ^- ]]; then
            local splitCommand="$(echo t"${arg:1}" | fold -w1 | tr '\n' ' ')"
            for flag in $splitCommand; do
                flags+=("\"--$flag\"")
            done
        fi
    done

    # Assign the flags to the reference array
    echo "${flags[@]}"
}

composite_help_get_rest() {
    reset_ifs
    local non_flags=()

    # Split the remaining arguments into non-flags (does not start with --)
    for arg in "$@"; do
        # arg=$(echo "$arg" | sed "s/ /__LSR_SPACE_PLACEHOLDER__/g")
        if [[ (! "$arg" =~ ^--) && (! "$arg" =~ ^-) ]]; then
            non_flags+=("\"$arg\"")
        fi
    done

    echo "${non_flags[@]}"
}

# Function to check if a flag is in the flags array
composite_help_contains_flag() {
    flagName=$1
    shift
    flags=("$@")

    for flag in "${flags[@]}"; do
        if [[ "$flag" == *"="* ]]; then
            flag="${flag%%=*}"  # Everything before the first '='
        fi

        if [[ "$flag" == "--$flagName" ]]; then
            return 0  # Flag is found
        fi
    done

    return 1  # Flag not found
}

composite_help_get_flag_value() {
    flagName=$1
    shift
    flags=("$@")

    for flag in "${flags[@]}"; do
        # Check if flag has an '=' sign
        if [[ "$flag" == "--$flagName="* ]]; then
            value="${flag#*=}"  # Extract everything after the '='
            echo "$value"        # Output the value to the caller
            return 0             # Success
        fi

        # Also support the form without '=' for a flag switch (optional)
        if [[ "$flag" == "--$flagName" ]]; then
            echo "true"          # For flags like --flag without a value
            return 0             # Success
        fi
    done

    return 1  # Flag not found
}

# Function to get the value of a flag
composite_help_flag_get_value() {
    flagName=$1
    shift
    flags=("$@")

    for flag in "${flags[@]}"; do
        if [[ "$flag" == "$flagName"* ]]; then
            # Extract the value after '='
            value="${flag#*=}"
            echo "$value"
            return
        fi
    done

    # Return an empty string if the flag doesn't have a value or isn't found
    echo ""
}

# Helper functions for creating composite commands
composite_help_command() {
    
    # Arguments
    local filter=$1               # Filter for what help commands to show
    local argument_count=$2       # Number of arguments
    shift 2
    echo "$2"

    return
    local defined_commands=("$@")  # List of commands

    # Dont do anything if any arguments were given to the main function
    if [ "$argument_count" -gt 0 ]; then
        return
    fi

    # lcompIterate over the commands and print only the ones that match the filter
    echo "Usage: '${defined_commands[@]}' "
    for cmd in "${defined_commands[@]}"; do
        echo " - $cmd"

        # if [[ "$filter" == "" || "$cmd" == "$filter"* ]]; then
            
        #     # echo " - "
        # fi
    done
}
########################################
# Start of LSR module #5               #
# Injected LSR module: git_helpers.sh  #
# Number of lines: 60                  #
# Filesize: 1.77 KB                    #
########################################
alias gitusers="git_users_main_command"

git_branch_exists() {
    branchName="$1"

    # Check if the branch exists locally
    local localBranches
    localBranches=$(git branch --list "$branchName")
    if [[ -n "$localBranches" ]]; then
        return 0  # Branch exists locally
    fi

    # Check if the branch exists remotely
    local remoteBranches
    remoteBranches=$(git branch --all | grep -w "remotes/origin/$branchName")
    if [[ -n "$remoteBranches" ]]; then
        return 0  # Branch exists remotely
    fi

    # If branch doesn't exist locally or remotely
    return 1  # Branch does not exist
}

find_git_user_by_alias() {
    local alias=$1

    if [[ -z $alias ]]; then
        print_error "find_git_user_by_alias expects an argument for the alias to search"
        return 1
    fi

    localsettings_eval "( .gitusers | to_entries | map(select(.value.aliases[] == \"$alias\")) )[0] | { \"identifier\": .key, \"fullname\": .value.fullname, \"aliases\": .value.aliases } "
}

parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -n $branch ]]; then
        echo "$branch"
    fi
}

# Display your current branch name and commit count:
git_info() {
    branch=$(git rev-parse --abbrev-ref HEAD)
    commits=$(git rev-list --count HEAD)
    echo "On branch: $branch, commits: $commits"
}

alias gitlog='git log --pretty=format:"%C(green)%h %C(blue)%ad %C(red)%an%C(reset): %C(yellow)%s%C(reset)" --color --date=format:"%d/%m/%Y %H:%M"'
alias s='git status'
alias co='git checkout'
alias br='git branch --all'
alias ci='git commit'
alias st='git stash'

# alias rb='git rebase'
# alias rba='git rebase --abort'
# alias rbc='git rebase --continue'
alias delete='git branch -d'
alias d="!f() { git branch -d $1 && git push origin --delete $1; }; f"
#########################################
# Start of LSR module #6                #
# Injected LSR module: tmux_helpers.sh  #
# Number of lines: 437                  #
# Filesize: 13.52 KB                    #
#########################################
# TODO: Fix bug where when pane 1 is closed, pane 2 will become 1 and thus take its name

DEBUG_CACHE_WRITING=false
INDENT="    "
INACTIVE_LIST_ITEM=" - "
ACTIVE_LIST_ITEM=" * "
PANE_NAME_FILE="$HOME/scripts/local_data/tmp/tmux_pane_names.txt"

alias spf="sync_pane_file"

sync_pane_file() {
    > $PANE_NAME_FILE
    save_pane_names
}

get_pane_id() {
    if [ -z "$1" ]; then
        echo "Usage: get_pane_id <pane_number>"
        return 1
    fi

    local pane_number="$1"

    # Ensure the pane number is a valid number (for safety)
    if [[ ! "$pane_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Pane number must be a number."
        return 1
    fi

    # Get the pane ID corresponding to the pane number
    local pane_id=$(tmux list-panes -F "#{pane_index} #{pane_id}" | awk -v num="$pane_number" '$1 == num {print $2}'  | tr -d '%')

    if [ -z "$pane_id" ]; then
        echo "No pane found with number: $pane_number"
        return 1
    fi

    # Output the pane ID
    echo "$pane_id"
}

get_pane_number() {
    if [ -z "$1" ]; then
        echo "Usage: get_pane_number <pane_id_without_percentage>"
        return 1
    fi

    local pane_id="$1"
    
    # Ensure the pane ID is a valid number (for safety)
    if [[ ! "$pane_id" =~ ^[0-9]+$ ]]; then
        echo "Error: Pane ID must be a number."
        return 1
    fi

    local pane_index=$(tmux list-panes -F "#{pane_id},#{pane_index}" | grep "%${pane_id}" | cut -d',' -f2)

    if [ -z "$pane_index" ]; then
        echo "No pane found with ID: %$pane_id"
        return 1
    fi

    # Output the pane index
    echo "$pane_index"
}

debug_message() {
    # echo $($DEBUG_CACHE_WRITING = true)
    if [[ "$DEBUG_CACHE_WRITING" = true ]]; then
        print_debug "$1"
    fi
}

# Load pane names from the file into the associative array
declare -gA pane_names

set_stored_pane_name() {
    local key="$1"
    local value="$2"
    pane_names["$key"]="$value"
}

sync_pane_names() {
    debug_message "SYNCING PANE NAMES..."
    
    # Make a copy of the old pane names
    declare -A old_pane_names 
    for key in "${!pane_names[@]}"; do
        old_pane_names["$key"]="${pane_names[$key]}"
    done

    # Clear the pane names array and set it to the save file
    unset pane_names
    declare -gA pane_names
    load_pane_names

    # Try to find new, unregistered panes that are not named yet across all sessions
    sessions=$(tmux list-sessions -F '#S')  # Get all session names

    for session in $sessions; do
        current_windows=$(tmux list-windows -t "$session" -F '#I')  # Get window indices for each session

        for window in $current_windows; do
            # List all panes in the current window
            panes=$(tmux list-panes -t "$session:$window" -F '#D')

            for pane in $panes; do
                # Create a key for the current pane
                pane_key="$session:$window:$pane"

                # Check if this pane is not already in pane_names
                if [[ -z "pane_names[$pane_key]" ]]; then
                    # If it's a new pane, assign it a default name
                    debug_message "SYNCING: Storing pane $pane_key in save file as its not in it yet..."
                    set_stored_pane_name "$pane_key" "Unnamed Pane"
                fi
            done
        done
    done
    
    unset old_pane_names
    save_pane_names
}

list_panes() {
    echo "Current Pane Names:"
    
    # Check if pane_names has any entries
    if [ ${#pane_names[@]} -eq 0 ]; then
        echo "No named panes found."
        return
    fi

    # Loop through the associative array and print keys and values
    for key in "${!pane_names[@]}"; do
        echo "$key: ${pane_names[$key]}"
    done
}

load_pane_names() {
    debug_message "LOADING PANE NAMES..."

    # Ensure the pane names file exists before attempting to load it
    if [[ ! -f "$PANE_NAME_FILE" ]]; then
        return
    fi

    unset pane_names
    declare -gA pane_names

    # Read the pane names from the file
    while IFS=':' read -r session window pane name; do
        # Check if all variables are set and not empty
        if [[ -n "$session" && -n "$window" && -n "$pane" && -n "$name" ]]; then
            pane_names["$session:$window:$pane"]="$name"
        else
            echo "Skipping malformed line: '$session:$window:$pane:$name'"
        fi
    done < "$PANE_NAME_FILE"
}

save_pane_names() {
    debug_message "SAVING PANE NAMES..."
    # Ensure the directory exists
    local dir_name=$(dirname "$PANE_NAME_FILE")
    mkdir -p $dir_name

    > "$PANE_NAME_FILE"  # Clear the file before saving
    for key in "${!pane_names[@]}"; do
        session=$(echo "$key" | cut -d':' -f1)
        window=$(echo "$key" | cut -d':' -f2)
        pane=$(echo "$key" | cut -d':' -f3)
        name="${pane_names[$key]}"
        echo "$session:$window:$pane:$name" >> "$PANE_NAME_FILE"
    done
}

# Short aliases for Pane manipulation
alias ml="tmux select-pane -L"          # Move a pane left
alias mr="tmux select-pane -R"          # Move a pane right
alias md="tmux select-pane -D"          # Move a pane down
alias mu="tmux select-pane -U"          # Move a pane up
alias shor="tmux split-window -h"       # Splitting pane horizontal
alias sver="tmux split-window -v"       # Splitting pane vertical
alias pane="current_pane"               # Rename pane
alias rp="rename_pane"                  # See current pane

expand_left()  { tmux resize-pane -L "${1:-5}"; } # Expand a pane left
expand_right() { tmux resize-pane -R "${1:-5}"; } # Expand a pane right
expand_down()  { tmux resize-pane -D "${1:-5}"; } # Expand a pane down
expand_up()    { tmux resize-pane -U "${1:-5}"; } # Expand a pane up
alias el="expand_left"      # Expand a pane left
alias er="expand_right"     # Expand a pane right
alias ed="expand_down"      # Expand a pane down
alias eu="expand_up"        # Expand a pane up

# Short aliases for Window manipulation
alias wr="tmux select-window -t +1" # Move a window right
alias wl="tmux select-window -t -1" # Move a window left
alias wn="tmux new-window" # New window
alias wk="tmux kill-window" # Close window
alias rw="rename_window" # Rename window

# Short aliases for Session manipulation
alias sr="tmux rename-session"
alias sl=""
alias sn="tmux new-session"
alias sc="tmux kill-session"
alias sw=""

# Short aliases for other things
alias tls="tlist"                       # List all rmux sessions

rename_window() {
    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')

    old_name=$(tmux display -p '#W')

    tmux rename-window "$1"
    echo "Renamed window '$old_name' to '$1'"
}

declare -A pane_names
rename_pane() {
    sync_pane_names

    local pane_name

    if [[ $# -eq 1 ]]; then
        # Only one argument provided: it's the new name, use the current pane
        pane_name=$1
        current_pane=$(tmux display-message -p '#D' | tr -d '%')  # Get the current pane id
    elif [[ $# -eq 2 ]]; then
        # Two arguments provided: first is the pane index, second is the new name
        current_pane=$(get_pane_id $1)
        echo "going for pane $target_pane"
        pane_name=$2
    else
        echo "Usage: rename_pane [<pane_number>] <new_name>"
        return 1
    fi

    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')

    # Create a unique key for the pane
    pane_key="${current_session}:${current_window}:${current_pane}"

    old_name=${pane_names[$pane_key]:-"Unnamed Pane"}
    pane_names[$pane_key]="$pane_name"

    save_pane_names

    # Output confirmation message
    if [[ "$old_name" == "Unnamed Pane" ]]; then
        echo "Named current pane '$current_pane' to '$pane_name'"
    else
        echo "Renamed pane '$old_name' to '$pane_name'"
    fi
}

current_pane() {
    sync_pane_names
    save_pane_names
    load_pane_names

    # Get the current session, window, and pane ID (instead of pane number)
    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')
    current_pane_id=$(tmux display -p '#D' | tr -d '%')  # Unique pane ID

    # Create a unique key for the current pane using the pane ID
    pane_key="${current_session}:${current_window}:${current_pane_id}"
    current_pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}

    # Display information about the current session, window, and pane
    echo -e "${ACTIVE_LIST_ITEM}Session $current_session: \e[1;34m$current_session\e[0m"
    echo -e "${INDENT}${ACTIVE_LIST_ITEM}\e[1;32mWindow $current_window: Window $current_window\e[0m"
    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $current_pane_id: $current_pane_name\e[0m"
}

tlist() {
    load_pane_names
    sync_pane_names

    # Get the active session, window, and pane
    active_session=$(tmux display-message -p '#S')
    active_window=$(tmux display-message -p '#I')
    active_pane=$(tmux display-message -p '#D' | tr -d '%')

    # List all tmux sessions
    tmux list-sessions -F '#S' | nl -w1 -s': ' | while read session; do
        session_number=$(echo "$session" | cut -d':' -f1 | xargs)  # Get the session number
        session_name=$(echo "$session" | cut -d':' -f2 | xargs)    # Get the session name

        # Check if session is active
        if [ "$session_name" == "$active_session" ]; then
            echo -e "${ACTIVE_LIST_ITEM}\e[1;34mSession $session_number: $session_name\e[0m"
        else
            echo -e "${INACTIVE_LIST_ITEM}\e[1;34mSession $session_number: $session_name\e[0m"
        fi

        # List windows in the current session
        tmux list-windows -t "$session_name" -F '#I: #W' | while read -r window; do
            # Extract window number and name
            window_number=$(echo "$window" | cut -d':' -f1 | xargs)  # Get the window number
            window_name=$(echo "$window" | cut -d':' -f2 | xargs)    # Get the window name

            # Check if window is active
            if [ "$session_name" == "$active_session" ] && [ "$window_number" == "$active_window" ]; then
                echo -e "${INDENT}${ACTIVE_LIST_ITEM}\e[1;32mWindow $window_number: $window_name\e[0m"
            else
                echo -e "${INDENT}${INACTIVE_LIST_ITEM}\e[1;32mWindow $window_number: $window_name\e[0m"
            fi

            # List panes in the current window
            tmux list-panes -t "$session_name:$window_number" -F '#D: #T' | while read -r pane; do
                pane_id=$(echo "$pane" | cut -d':' -f1 | xargs | tr -d '%')  # Get the pane number
                pane_number=$(get_pane_number $pane_id)

                # Create a unique key for the pane
                pane_key="${session_name}:${window_number}:${pane_id}"
                pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}

                # Check if pane is active
                if [ "$session_name" == "$active_session" ] && [ "$window_number" == "$active_window" ] && [ "$pane_id" == "$active_pane" ]; then
                    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $pane_id($pane_number): $pane_name\e[0m"
                else
                    echo -e "${INDENT}${INDENT}${INACTIVE_LIST_ITEM}\e[1;33mPane $pane_id($pane_number): $pane_name\e[0m"
                fi
            done
        done    
    done
}

# Expand pane up by a specified size (default is 5)
resize_up() {
    local size=  # Default to 5 if no argument is provided
    
}

# Command to run a command in a different pane number
run_in_pane() {
    load_pane_names

    # Get the current pane number
    local current_pane=$(tmux display-message -p '#D')
    
    # Get the target pane number and remove it from
    # the commandline argument list
    local target_pane=$1
    shift
    
    # Run the command in the target pane
    local command="$*"
    tmux send-keys -t $target_pane "$command" C-m
}

run_in_pane_until_finished() {
    load_pane_names

    # Get the target pane number and command
    local target_pane=$1
    shift
    local command="$*"

    # Run the command in the target pane
    tmux send-keys -t $target_pane "$command" C-m

    # Wait for the pane to stop showing activity (becomes idle)
    while true; do
        # Capture pane content and check for any command prompt (indicating readiness)
        local pane_output=$(tmux capture-pane -pt $target_pane -S - )

        # If the last line is a prompt (customize based on your shell prompt), break the loop
        if [[ $pane_output =~ \$$  ]]; then  # Example: match shell prompt ending with "$ "
            break
        fi

        # Sleep to avoid rapid polling
        sleep 1
    done
}

# Print the current pane number
alias tcur="tmux display-message -p 'Current pane number: #D'"

# Use this to start tmux:
#   - Creates new session if none found
#   - if session found, use that one
t() {
    # Clear all pane names
    unset pane_names
    declare -gA pane_names
    sync_pane_file
    save_pane_names
    
    tmux has-session -t "dev" 2>/dev/null
    if [ $? != 0 ]; then
        echo "Creating new session: dev"
        tmux new -s "dev"
    else
        echo "Attaching to existing session: dev"
        tmux attach-session -t "dev"
    fi
}

tclose() {
    local pane_index=$1

    # If no pane index was given
    if [[ -z "$pane_index" ]]; then
        tmux kill-pane
    else # If pane index was specified
        tmux kill-pane -t "%$(get_pane_id $pane_index)"
    fi
}

tcloseall() {
    tmux kill-pane -a
    echo "All panes in the current window killed."
    tclose # Close the last pane
}

# Setting settings of vim
setup_tmux_config() {
    local tmuxconfig_file="$HOME/.tmux.conf"

    # Copy the config file
    cp ~/scripts/extra_config_files/.tmux.conf ~/.tmux.conf
}

alias tca="tcloseall"
alias rip="run_in_pane"
alias ripuf="run_in_pane_until_finished"
alias tc="tclose"

##################################
# Start of LSR module #7         #
# Injected LSR module: utils.sh  #
# Number of lines: 199           #
# Filesize: 5.60 KB              #
##################################
# TODO:
# - scrollTable command
# - actionTable command
# - select command
# - list command
# - confirm command
# - progressbar command

table() {
    local header_csv="$1"
    IFS=',' read -r -a headers <<< "$header_csv"

    # Parse the headers and save the lengths
    local colCount="${#headers[@]}"
    local colLengths=()
    for header in "${headers[@]}"; do
        local headerLength="${#header}"
        colLengths+=("$headerLength")
    done

    shift

    # Loop trough the body, looking if we need to extend the col width
    for row in "${@:1}"; do

        # Replace escaped commas with a placeholder
        row=$(echo "$row" | sed 's/\\,/__ESCAPED_COMMA__/g')

        IFS=',' read -r -a rowValues <<< "$row"
        for ((i = 0; i < ${#rowValues[@]}; i++)); do
            local value=$(echo "${rowValues[i]}" | sed 's/__ESCAPED_COMMA__/,/g')
            local valueLength="${#value}"
            local currColWidth="${colLengths[i]}"

            if [[ $valueLength -gt $currColWidth ]]; then
                colLengths[$i]="$valueLength"
            fi

        done
    done

    # Print the top bar
    echo -n "┌"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $((colLength + 2))))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┬"
        fi
        ((currentColIndex++))
    done
    echo -n "┐"
    echo ""

    # Print header bar
    for ((i = 0; i < ${#headers[@]}; i++)); do
        local header="${headers[i]}"
        local headerLength="${colLengths[i]}"
        local currHeaderLength="${#header}"

        echo -n "│ $header"
        echo -n "$(printf ' %.0s' $(seq 1 $(( headerLength - currHeaderLength + 1 ))))"
    done
    echo "│"

    # Print header bottom
    echo -n "├"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $((colLength + 2))))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┼"
        fi
        ((currentColIndex++))
    done
    echo -n "┤"
    echo ""

    # Print the table body
    for row in "${@:1}"; do
        
        # Replace escaped commas with a placeholder
        row=$(echo "$row" | sed 's/\\,/__ESCAPED_COMMA__/g')

        IFS=',' read -r -a rowValues <<< "$row"
        for ((i = 0; i < ${#rowValues[@]}; i++)); do
            local value=$(echo "${rowValues[i]}" | sed 's/__ESCAPED_COMMA__/,/g')
            local currColLength="${colLengths[i]}"
            local currValuelength="${#value}"
            local numberOfSpacesNeeded="$((currColLength - currValuelength + 1))"

            echo -n "│ $value"
            echo -n "$(printf ' %.0s' $(seq 1 $numberOfSpacesNeeded))"
        done
        echo "│"
    done

    # Print the bottom bar
    echo -n "└"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $((colLength + 2))))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┴"
        fi
        ((currentColIndex++))
    done
    echo -n "┘"
    echo ""
}

list() {
    eval "flags=($(composite_help_get_flags "$@"))"
    eval "args=($(composite_help_get_rest "$@"))"

    local selectable="false"
    local prefix=" - "
    local selected_prefix=" > "
    local selected_value=""

    if composite_help_contains_flag prefix "${flags[@]}"; then
        prefix=$(composite_help_get_flag_value prefix "${flags[@]}")
    fi
    
    if composite_help_contains_flag selected-prefix "${flags[@]}"; then
        selected_prefix=$(composite_help_get_flag_value selected-prefix "${flags[@]}")
    fi

    if composite_help_contains_flag selected "${flags[@]}"; then
        selected_value=$(composite_help_get_flag_value selected "${flags[@]}")
    fi


    set -- "${args[@]}"

    local listName=$1
    local listItems=$2

    echo "$listName:"

    IFS=',' # Set the Internal Field Separator to comma
    for listItem in $listItems; do
        if [[ "$listItem" == "$selected_value" ]]; then
            echo -e "$selected_prefix$listItem"
        else
            echo -e "$prefix$listItem"
        fi
    done
    reset_ifs
}

selectable_list() {
    title=$1
    selected=0
    local -n return_ref=$2
    options_list=$3
    IFS=',' read -r -a options <<< "$options_list"
    reset_ifs

    # Function to display the menu
    print_menu() {
        clear
        echo "Use Arrow Keys to navigate, Enter to select:"
        list "$title" "$options_list" "--selected=${options[$selected]}" --selected-prefix="\e[1;32m => " --prefix="\e[0m  - "
        echo -ne "\e[0m"
    }

    # Capture arrow keys and enter key
    while true; do
        print_menu

        # Read one character at a time with `-s` (silent) and `-n` (character count)
        read -rsn1 input

        # Check for arrow keys or Enter
        case "$input" in
            $'\x1b')  # ESC sequence (for arrow keys)
                read -rsn2 -t 0.1 input  # Read next two chars
                case "$input" in
                    '[A')  # Up arrow
                        ((selected--))
                        if [ $selected -lt 0 ]; then
                            selected=$((${#options[@]} - 1))
                        fi
                        ;;
                    '[B')  # Down arrow
                        ((selected++))
                        if [ $selected -ge ${#options[@]} ]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            '')  # Enter key
                return_ref="${options[$selected]}"
                break
                ;;
        esac
    done
}
#################################
# Start of LSR module #8        #
# Injected LSR module: proj.sh  #
# Number of lines: 240          #
# Filesize: 7.44 KB             #
#################################
alias cproj=current_project
alias proj=project
alias p=project
alias sproj="select_project"
alias sp="select_project"
alias rproj=remove_project
alias nproj=new_project
alias sprojurl=set_project_url
alias gprojurl=get_project_url
alias rprojurl=remove_project_url

select_project() {
    projects_output=$(project)
    projects_list=$(echo "$projects_output" | grep '^ - ' | awk '{sub(/^ - /, ""); if (NR > 1) printf ","; printf "%s", $0} END {print ""}')
    
    local value=""
    selectable_list "Select a project" value "$projects_list"
    project $value
}

get_current_project_label() {
    echo "$(cproj)"
}

set_project_url() {
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    local url="$1"

    if [[ -z "$url" ]]; then
        echo "Usage: proj_url <Url>"
        return 1
    fi

    local project_name=$(cproj)
    if [[ -z "$project_name" ]]; then
        echo "Current directory is not a defined project"
        return 1
    fi

    yq eval -i ".projects.$project_name.url = \"$url\"" "$yaml_file"
}

remove_project_url() {
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    
    local project_name=$(cproj)
    if [[ -z "$project_name" ]]; then
        echo "Current directory is not a defined project"
        return 1
    fi

    yq eval -i ".projects.$project_name.url = null" "$yaml_file"
}

get_project_url() {
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    
    local project_name=$(cproj)
    if [[ -z "$project_name" ]]; then
        echo "Current directory is not a defined project"
        return 1
    fi

    localsettings_get ".projects.$project_name.url"
}

# Function to add a new project to local_settings.yml
new_project() {
    local project_name="$1"
    local project_dir="$2"
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"

    if [[ -z "$project_name" ]]; then
        echo "Usage: nproject <project_name> [project_directory]"
        return 1
    fi

    if [[ -z "$project_dir" ]]; then
        # If no directory is provided, set a default directory (or handle accordingly)
        project_dir="."  # Convert to lowercase and set a default directory
    fi

    # Expand the project dir if it is relative
    project_dir=$(realpath -m "$project_dir" 2>/dev/null) || project_dir="$(cd "$project_dir" && pwd)"

    if [[ -f "$yaml_file" ]]; then
        # Check if the project already exists
        if [[ $(yq eval ".projects | has(\"$project_name\")" "$yaml_file") == "true" ]]; then
            echo "Project '$project_name' already exists in local_settings."
        else
            # Add the new project entry
            yq eval -i ".projects.$project_name = {\"dir\": \"$project_dir\", \"url\": null}" "$yaml_file"
            echo "Added project '$project_name' to local_settings."
        fi

        localsettings_reformat
    else
        echo "YAML file not found: $yaml_file"
    fi
}

# Function to remove a project from local_settings.yml
remove_project() {
    local project_name="$1"
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"

    if [[ -z "$project_name" ]]; then
        echo "Usage: premove <project_name>"
        return 1
    fi

    if [[ -f "$yaml_file" ]]; then
        # Check if the project exists in the YAML file
        if [[ $(yq eval ".projects | has(\"$project_name\")" "$yaml_file") == "true" ]]; then
            # Remove the project entry
            yq eval "del(.projects[\"$project_name\"]) " "$yaml_file" -i
            echo "Removed project '$project_name' from local_settings."
        else
            echo "Project '$project_name' not found in local_settings."
        fi
    else
        echo "YAML file not found: $yaml_file"
    fi
}

project() {
    load_yaml_projects

    local show_dirs=false

    # Parse options
    while [[ "$1" == -* ]]; do
        case "$1" in
            --dirs)
                show_dirs=true
                shift
                ;;
            *)
                echo "Usage: proj [project_name] [--dirs]"
                return 1
                ;;
        esac
    done

    # Check if a project name was provided
    if [[ -n "$1" ]]; then
        # Check if the provided project exists in the combined projects array
        if [[ -n "${yaml_projects[$1]}" ]]; then
            if [[ -d "${yaml_projects[$1]}" ]]; then
                cd "${yaml_projects[$1]}" || echo "Failed to navigate to ${yaml_projects[$1]}"
            else
                echo "Directory does not exist: ${yaml_projects[$1]}"
            fi
        else
            echo "Project not found. Available projects:"
            list_projects "$show_dirs"  # Pass the option to list_projects
        fi
    else
        # No project name provided, just list all projects
        list_projects "$show_dirs"  # Pass the option to list_projects
    fi
}

current_project() {
    local cwd
    cwd=$(pwd | xargs)  # Get the current working directory

    # Get the list of projects silently
    local project_list
    project_list=$(proj --dirs 2>/dev/null | sed '1d')  # Suppress errors and output

    # Parse the project list
    while IFS= read -r line; do
        # Extract project name and directory path
        local project_name
        local project_path
        project_name=$(echo "$line" | awk -F ': ' '{print $1}' | sed 's/\x1B\[[0-9;]*m//g')
        project_path=$(echo "$line" | awk -F ': ' '{print $2}' | sed 's/\x1B\[[0-9;]*m//g')
        project_path=$(echo "$project_path" | xargs)

        # Compare the project path with the current working directory
        if [[ "$cwd" == "$project_path" ]]; then
            echo "$project_name" | awk -F ' - ' '{print $2}'  # Return the project name if it matches
            return 0
        fi
    done <<< "$project_list"
    return 1
}

# Function to load additional projects from local_settings.yml
load_yaml_projects() {
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    declare -gA yaml_projects=()  # Temporary array to store YAML projects

    if [[ -f "$yaml_file" ]]; then
        
        
        # Parse YAML and add entries to the yaml_projects array using yq
        while IFS="=" read -r key value; do
            
            key=$(echo "$key" | xargs)    # Trim whitespace
            value=$(echo "$value" | xargs) # Trim whitespace

            # Expand ~ to $HOME if it's present
            if [[ "$value" == "~"* ]]; then
                value="${HOME}${value:1}"  # Replace ~ with $HOME
            fi

            yaml_projects["$key"]="$value"
        done < <(lseval ".projects | to_entries | .[] | .key + \"=\" + .value.dir")
    fi
}

# Function to list all available projects, highlighting the current project in green
list_projects() {
    load_yaml_projects
    local current_dir=$(pwd)
    local green='\033[0;32m'
    local reset='\033[0m'

    echo "Available projects:"
    local show_dirs="$1"
    for key in "${!yaml_projects[@]}"; do
        # Determine if the current project is the active one
        if [[ "${yaml_projects[$key]}" == "$current_dir" ]]; then
            # Highlight the current project in green
            if [[ "$show_dirs" == true ]]; then
                echo -e "${green} - $key: ${yaml_projects[$key]}${reset}"
            else
                echo -e "${green} - $key${reset}"  # Green highlight for the project name
            fi
        else
            # Regular output for other projects
            if [[ "$show_dirs" == true ]]; then
                echo " - $key: ${yaml_projects[$key]}"
            else
                echo " - $key"
            fi
        fi
    done
}
####################################
# Start of LSR module #9           #
# Injected LSR module: aliases.sh  #
# Number of lines: 28              #
# Filesize: 793 B                  #
####################################
# LSR Module that contains standalone aliases

reload_bash() {
    source ~/.bashrc
    print_success '~/.bashrc reloaded!'
}

backup() {
    local backup_location="$1-backup"
    cp $1 $backup_location -r
}

alias hosts='powershell.exe -Command "Start-Process \"C:\Program Files\Sublime Text\sublime_text.exe\" -ArgumentList \"C:\Windows\System32\Drivers\etc\hosts\" -Verb RunAs"'
alias refreshdns='powershell.exe -Command "ipconfig /flushdns"'
alias c='clear'
alias cf='cfind'
alias today='work --date=today'
alias yesterday='work --date=yesterday'
alias l="ls -la"
alias rb="reload_bash"
alias files="explorer.exe ."
alias subl='"/mnt/c/Program Files/Sublime Text/sublime_text.exe"'

unalias joke 2>/dev/null
joke() {
    curl -H "Accept: text/plain" https://icanhazdadjoke.com/
    echo
}

####################################
# Start of LSR module #10          #
# Injected LSR module: laravel.sh  #
# Number of lines: 215             #
# Filesize: 5.81 KB                #
####################################
alias fresh="fresh_install_sail"

npmscripts() {
    local path="package.json"
    
    if [ ! -f "$path" ]; then
        echo "Error: $path not found."
        return 1
    fi

    # Extract script names using jq
    if command -v jq &> /dev/null; then
        echo "Available npm scripts:"
        jq -r '.scripts | keys[]' "$path"
    else
        echo "Error: jq is required to parse JSON. Please install jq."
        return 1
    fi
}

get_first_npm_script() {
    if [ ! -f package.json ]; then
        echo "package.json not found."
        return 1  # Exit with error if package.json is missing
    fi

    # Hardcoded priority order: watch > dev > start
    local priority_order=("watch" "dev" "start")

    # Extract scripts using jq
    local scripts
    scripts=$(jq -r '.scripts | to_entries[] | .key' package.json)

    # Check each script in the hardcoded priority order
    for script in "${priority_order[@]}"; do
        if echo "$scripts" | grep -q "^$script$"; then
            # Return the first matching script based on priority
            echo "$script"
            return 0
        fi
    done

    echo "No matching npm scripts found."
    return 1  # Exit with error if no matching scripts are found
}

create_start_layout() {
    # Rename the window to the current project
    local current_project="$(cproj)"

    if [[ $current_project == "" ]]; then
        print_error "Cannot start project because current dir is not a laravel project configured in proj"
        return 1
    fi

    # Create the pane layout
    tmux split-window -h
    tmux select-pane -L
    tmux split-window -v
    tmux select-pane -R

    rename_window "$current_project"
    rename_pane 0 "$current_project-sail"
    rename_pane 1 "$current_project-npm"
    rename_pane "$current_project-terminal"
}

switch() {
    local project=$1

    # Usage printing
    if [[ -z $project ]]; then
        echo "Usage: switch <projectname>"
        return 0
    fi

    # Check if project exists
    local failedSwitching=$(proj "$project" | grep -q "Project not found. Available projects:" && echo true || echo false)

    # Print error
    if [[ $failedSwitching == true ]]; then
        print_error "Cannot switch to project '$project' because it does not exist"
        proj
        return 1
    fi

    stop
    start $project
}

stop() {
    # Close everything except the current terminal
    print_info "Closing npm pane"
    run_in_pane 1 C-c
    sleep 1
    tclose 1
    print_info "Closing sail pane"
    run_in_pane 0 C-c
    sleep 3
    tclose 0
    cd ~
}

start() {
    # If argument is given, go to that project
    local project=$1
    local failedSwitching=$(proj "$project" | grep -q "Project not found. Available projects:" && echo true || echo false)

    # Failed switching to project
    if [[ $failedSwitching == true ]]; then
        print_error "Cannot start project '$project' because it does not exist"
        proj
        return 1
    fi

    # Jump to project if needed
    if [[ -n "$project" ]]; then
        proj "$project"
    else # No project was given
        # If current dir is not a project, dont continue
        project=$(cproj)
        if [[ -z "$project" ]]; then
            print_error "Cant start because current dir is not a defined project"
            return 1
        fi
    fi

    clear

    create_start_layout

    run_in_pane 0 "clear"
    run_in_pane 1 "clear"
    run_in_pane 2 "clear"
    
    run_in_pane 2 el 20
    run_in_pane 2 clear
    run_in_pane 2 tls

    # TODO: what if no package.json is available?
    # TODO: what if no laravel available?
    # TODO: open URL if available

    # Get the first available npm script
    npm_script=$(get_first_npm_script)

    # Start npm, make sure no browsers get opened
    if grep -q "\"$npm_script\": \"vite" package.json; then
        print_info "starting npm with 'npm run $npm_script -- --no-open'"
        run_in_pane 1 "npm run $npm_script -- --no-open"
    else
        print_info "starting npm with 'npm run $npm_script'"
        run_in_pane 1 "npm run $npm_script"
    fi

    # Open URL if available
    local projurl=$(get_project_url)
    if [[ "$projurl" == "null" ]]; then
        # Start sail
        print_info "starting sail..."
        run_in_pane 0 sail up
    else
        run_in_pane 2 "(sleep 5; explorer.exe $projurl) &" 
        print_info "starting sail..."
        run_in_pane 0 sail up
    fi

    return 0
}

# Command to freshly install all dependancies and containers
fresh_install_sail() {
    # Check if --remove-docker-image was provided
    if [[ "$1" == "--remove-docker-image" ]]; then
        # Remove the Docker container, image, and volumes if they exist
        if [[ $(docker ps -aq -f "name=your_container_name") ]]; then
            ./vendor/bin/sail down --rmi all --volumes
            print_success "Docker containers, images, and volumes removed."
        else
            print_error "No Docker container found to remove."
        fi
    fi

    # Remove vendor directory if it exists
    if [ -d "vendor" ]; then
        rm -rf vendor
        print_success "Removed vendor directory."
    else
        print_info "No vendor directory found."
    fi

    # Remove node_modules directory if it exists
    if [ -d "node_modules" ]; then
        rm -rf node_modules
        print_success "Removed node_modules directory."
    else
        print_info "No node_modules directory found."
    fi

    # Install PHP dependencies
    composer install
    print_success "PHP dependencies installed."

    # Install JavaScript dependencies
    npm install
    print_success "JavaScript dependencies installed."

    # Build the containers (create if remove image was used, else build)
    if [[ "$1" == "--remove-docker-image" ]]; then
        ./vendor/bin/sail create
        print_success "Docker containers created."
    else
        ./vendor/bin/sail build
        print_success "Docker containers built."
    fi
}
###########################################
# Start of LSR module #11                 #
# Injected LSR module: local_settings.sh  #
# Number of lines: 224                    #
# Filesize: 6.03 KB                       #
###########################################
local_settings_file="$HOME/scripts/local_data/local_settings.yml"
local_settings_dir="$(dirname "$local_settings_file")"

alias lsget="localsettings_get"
alias lsset="localsettings_set"
alias lseval="localsettings_eval"
alias lsdel="localsettings_delete"
alias lssort="localsettings_sort"
alias lsformat="localsettings_reformat"

localsettings_ensureexists() {
    local field="$1"

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    local value=$(yq e "$field // \"\"" "$local_settings_file")

    # Create it if it does not exist
    if [[ -z "$value" ]]; then
        yq e -i "$field = null" "$local_settings_file"
        localsettings_reformat
    fi
}

localsettings_sort() {
    local field=$1

    if [ "$#" -ne 1 ]; then
        field="."
    fi

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    localsettings_eval_with_save "$field = ($field | to_entries | sort_by(.key) | from_entries)"
}

localsettings_delete() {
    local field=$1

    if [ "$#" -ne 1 ]; then
        echo "Usage: lsdel <path>"
        return 1  # Return an error code
    fi

    localsettings_eval_with_save "del($field)"
}

localsettings_eval_with_save() {
    local command="."

    if [[ -n $1 ]]; then
        command="$1"
    fi

    yq e -iP "$command" "$local_settings_file"
}

localsettings_eval() {
    local command="."

    if [[ -n $1 ]]; then
        command="$1"
    fi

    yq e -P "$command" "$local_settings_file"
}

localsettings_get() {
    local allow_create=false
    local field="."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --allow-create)
                allow_create=true
                shift
                ;;
            *)
                field="$1"
                shift
                ;;
        esac
    done

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    if $allow_create; then
        localsettings_ensureexists "$field"
    fi
    
    yq e -P "$field" "$local_settings_file"
}

localsettings_set() {
    local allow_create=false
    local field=""
    local value=""
    local unquoted=false

    # Display help message
    show_help() {
        print_normal "Usage: localsettings_set [OPTIONS] FIELD VALUE"
        print_normal "Set a value in the local settings file."
        print_normal ""
        print_normal "Options:"
        print_normal "  -a, --allow-create   Create the field if it doesn't exist."
        print_normal "  -u, --unquoted       Set the value without quotes."
        print_normal "  -h, --help           Display this help message."
        print_normal ""
        print_normal "Examples:"
        print_normal "  localsettings_set --allow-create .projects.aa '5'  # Set with quotes"
        print_normal "  localsettings_set --unquoted .projects.aa 5        # Set without quotes"
        print_normal "  localsettings_set .projects.aa '5'                  # Set with quotes"
        print_normal "  localsettings_set --help                             # Display help"
    }

    # Parse options using getopts
    while getopts "auh" opt; do
        case "$opt" in
            a) allow_create=true ;;
            u) unquoted=true ;;
            h) show_help; return 0 ;;
            \?) print_normal "Invalid option: -$OPTARG" >&2; return 1 ;;
            :) print_normal "Option -$OPTARG requires an argument." >&2; return 1 ;;
        esac
    done

    # Shift off the options processed by getopts
    shift $((OPTIND - 1))

    # Now handle long options manually
    for arg in "$@"; do
        case "$arg" in
            --allow-create)
                allow_create=true
                ;;
            --unquoted)
                unquoted=true
                ;;
            --help)
                show_help
                return 0
                ;;
            *)
                # Capture field and value
                if [[ -z "$field" ]]; then
                    field="$arg"  # First non-flag argument is the field
                elif [[ -z "$value" ]]; then
                    value="$arg"  # Second non-flag argument is the value
                else
                    print_normal "Error: Too many arguments." >&2
                    return 1
                fi
                ;;
        esac
    done

    # Check that both field and value are provided
    if [[ -z "$field" || -z "$value" ]]; then
        print_normal "Error: FIELD and VALUE are required." >&2
        return 1
    fi

    # Ensure field starts with a dot
    if [[ "$field" != .* ]]; then
        field=".$field"
    fi

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    # Ensure the field exists, conditionally
    if $allow_create; then
        localsettings_ensureexists "$field"
    fi

    print_normal "$unquoted"

    # Set the value
    if [[ $unquoted == "true" ]]; then
        # Set without quotes
        print_normal "YEEE"
        print_normal "yq e -i \"$field=$value\" \"$local_settings_file\""
        yq e -i "$field=$value" "$local_settings_file"
    else
        # Set with quotes
        yq e -i "$field=\"$value\"" "$local_settings_file"
    fi
}

yq_validate_only_lookup() {
    local field="$1"

    # Allow just a dot to return the entire structure
    if [[ "$field" == "." ]]; then
        return 0  # Valid case for root access
    fi

    # Regular expression to match valid field patterns
    if [[ ! "$field" =~ ^\.[a-zA-Z_-][a-zA-Z0-9_.-]*(\[[0-9]+\])?(\.[a-zA-Z_-][a-zA-Z0-9_.-]*(\[[0-9]+\])?)*$ ]]; then
        print_error "Invalid field format '${field}'. Only lookup notation is allowed (e.g., .projects or .projects.test-example).\n"
        return 1  # Exit with an error
    fi

    return 0
}

localsettings_reformat() {
    yq e -P '.' -i "$local_settings_file"
    localsettings_sort .projects
    localsettings_sort .gitusers
    localsettings_sort .
}
###############################################
# Start of LSR module #12                     #
# Injected LSR module: version_management.sh  #
# Number of lines: 57                         #
# Filesize: 1.41 KB                           #
###############################################
# Source the needed helper files
source ~/scripts/helpers.sh

BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
SETTINGS_FILE=~/scripts/_settings.yml
HISTORY_FILE=~/scripts/local_data/version_history.yml

alias linstall=lsr_install
alias lreinstall=lsr_reinstall
alias luninstall=lsr_uninstall



lsr_install() {
    ~/scripts/_install.sh
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
################################
# Start of LSR module #13      #
# Injected LSR module: vim.sh  #
# Number of lines: 36          #
# Filesize: 1004 B             #
################################
# Function to setup vim-plug for Vim
setup_vim_plug() {
    # Define the directory and file
    local vim_autoload_dir="$HOME/.vim/autoload"
    local plug_file="$vim_autoload_dir/plug.vim"

    # Create the autoload directory if it doesn't exist
    if [ ! -d "$vim_autoload_dir" ]; then
        mkdir -p "$vim_autoload_dir"
        print_info "Created directory: $vim_autoload_dir"
    fi

    # Download plug.vim if it doesn't exist
    if [ ! -f "$plug_file" ]; then
        curl -fLo "$plug_file" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        print_info "Downloaded vim-plug to $plug_file"
    fi
}


# Setting settings of vim
write_to_vimrc() {
    local vimrc_file="$HOME/.vimrc"

    setup_vim_plug

    # Hardcoded Vim configuration
    local vimrc_text="
source ~/scripts/extra_config_files/LukesVimConfig.vim
"

    # Create or clear the .vimrc file and write the hardcoded text
    echo "$vimrc_text" > "$vimrc_file"
}

write_to_vimrc
#################################
# Start of LSR module #14       #
# Injected LSR module: work.sh  #
# Number of lines: 101          #
# Filesize: 4.07 KB             #
#################################
# Command for seeing what people have done what work in my local repositories
work() {
    # Default values
    local date="$(date --date='yesterday' +%Y-%m-%d)"
    local filter_user=""
    local filter_project=""
    local original_pwd=$(pwd)

    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --date=*)
                date="${1#*=}"
                shift
                ;;
            --user=*)
                filter_user="${1#*=}"
                shift
                ;;
            --project=*)
                filter_project="${1#*=}"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Convert the specified date into the appropriate format
    date=$(date --date="$date" +%Y-%m-%d)

    echo -e "\n\033[34mSearching for commits on $date in all projects"

    # Loop through all subdirectories (assuming they are Git repositories)
    reset_ifs
    for repo in $(localsettings_eval ".projects[] | .dir"); do # Go through all of the projects
        if [ -d "$repo/.git" ]; then # If they are git repos
            # Change into the repository's directory, fetch all
            cd "$repo" || continue
            
            local projectlabel=$(localsettings_eval "(.projects | to_entries | map(select(.value.dir == \"$repo\")))[0].key")

            if [[ -n "$filter_project" && "$filter_project" != "$projectlabel" ]]; then
                continue;
            fi

            echo -e "\n\033[36m=== $projectlabel ===\033[0m"
            
            git fetch --all >/dev/null 2>&1

            # Get the commit logs from the specified date with full date and time
            commits=$(git log --all --remotes --branches --since="$date 00:00" --until="$date 23:59" --pretty=format:"%H|%an|%ae|%s|%ad" --date=iso --reverse)

            # Flag to check if any relevant commits were found
            local found_commits=false

            # Only display if there are commits
            if [ -n "$commits" ]; then
                # Loop through each commit to print the associated original branch name
                while IFS='|' read -r commit_hash username email commit_message commit_date; do
                    # Check if the user matches the filter (if specified)
                    local gituser=$(find_git_user_by_alias "$username")
                    local gituser_identifier=$(echo "$gituser" | yq e '.identifier' -)
                    
                    # Convert both the filter and the username/identifier to lowercase for case-insensitive comparison
                    local lower_username="$(echo "$username" | tr '[:upper:]' '[:lower:]')"
                    local lower_identifier="$(echo "$gituser_identifier" | tr '[:upper:]' '[:lower:]')"
                    local lower_filter_user="$(echo "$filter_user" | tr '[:upper:]' '[:lower:]')"

                    # Use identifier if it's set; otherwise, use the username
                    if [[ -n "$filter_user" && "$lower_filter_user" != "$lower_identifier" && "$lower_username" != "$lower_filter_user" ]]; then
                        continue
                    fi
                    
                    # Mark that we found a commit
                    found_commits=true
                    
                    # Format the commit date into hours and minutes (HH:MM)
                    time=$(date -d "$commit_date" +%H:%M)

                    # Map username to custom name
                    if [[ $gituser_identifier != "null" ]]; then
                        username=$gituser_identifier
                    fi

                    # Customize the output with colors
                    echo -e "\033[32m$username\033[0m@\033[33m$time\033[0m\033[0m: $commit_message"
                done <<< "$commits"
            fi

            # Print *No changes* if no relevant commits were found
            if [ "$found_commits" = false ]; then
                echo -e "\033[31m*No changes*\033[0m"
            fi
        fi
    done

    # Return to the original working directory
    cd "$original_pwd"
}
##################################
# Start of LSR module #15        #
# Injected LSR module: other.sh  #
# Number of lines: 719           #
# Filesize: 22.90 KB             #
##################################
jjjjLIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Update PS1 to include the Git branch if in a Git repo
get_project_branch_label() {
    local current_project=$(get_current_project_label)
    local current_branch=$(parse_git_branch)

    if [[ -n $current_project && -n $current_branch ]]; then
        echo -e " ($RED$current_project$RESET: $current_branch)"
    else
        if [[ -n $current_project ]]; then
            echo -e " ($RED$current_project$RESET)"
        fi

        if [[ -n $current_branch ]]; then
            echo -e " ($current_branch)"
        fi
    fi
}

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]$(get_project_branch_label)\$ '

get_dir_part() {
    current_project=$(cproj)
    if [[ -n $current_project ]]; then
        echo " 🔧 $current_project "
    else
        current_dir=$(pwd | sed "s|^$HOME|~|")
        echo " 📝 $current_dir "
    fi
}

get_git_part() {
    local current_branch=$(parse_git_branch)

    if [[ -n $current_branch ]]; then
        echo -e " 🔗 $current_branch "
    else
        echo ""
    fi
}

set_powerline_ps1() {
    local isRoot=0  # Default to not root
    if [[ ${EUID} -eq 0 ]]; then
        isRoot=1  # Set to 1 if running as root
    fi

    PS1=''

    local user_part
    local dir_part
    local git_part

    local black="0;0;0"
    local white="255;255;255"
    local red="255;0;0"
    local green="42;135;57"
    local blue="0;135;175"
    local yellow="179;127;55"

    # Define colors
    local blue_bg="\[\033[48;2;${blue}m\]"   # Blue Background
    local red_bg="\[\033[48;2;${red}m\]"     # Red Background
    local yellow_bg="\[\033[48;2;${yellow}m\]" # Darker Yellow Background
    local green_bg="\[\033[48;2;${green}m\]"    # Green Background
    local black_bg="\[\033[48;2;${black}m\]"    # Black Background

    local yellow_fg="\[\033[38;2;${yellow}m\]" # White Text
    local green_fg="\[\033[38;2;${green}m\]"       # Green Text
    local red_fg="\[\033[38;2;${red}m\]"       # Red Text
    local blue_fg="\[\033[38;2;${blue}m\]"       # Red Text
    local white_fg="\[\033[38;2;${white}m\]" # White Text
    local black_fg="\[\033[38;2;${black}m\]"       # Black Text

    if command_exists "profile"; then
        local current_profile="$(profile current)"
    fi

    if [[ $isRoot ]]; then
        user_part="${blue_bg}${white_fg} \u@\h - $current_profile ${blue_fg}${yellow_bg}"  # Blue arrow with yellow background
    else
        user_part="${red_bg}${white_fg} \u@\h - $current_profile ${red_fg}${yellow_bg}"  # Red arrow with yellow background
    fi

    # Directory part with darker yellow background and black text
    dir_part="${white_fg}${yellow_bg}\$(get_dir_part)${green_bg}${yellow_fg}"  # Yellow arrow with green background
    dir_ending_part="${white_fg}${yellow_bg}\$(get_dir_part)${black_bg}${yellow_fg}"

    # Git part with green background and white text
    git_part="${white_fg}${green_bg}\$(get_git_part)${green_fg}${black_bg}"  # Green arrow with blue background

    if [[ -z $(get_git_part) ]]; then
        PS1="${user_part}${dir_ending_part}\[\033[00m\] "
    else
        PS1="${user_part}${dir_part}${git_part}\[\033[00m\] "
    fi
}

do_before_prompt() {
    set_powerline_ps1
    localsettings_reformat
}

set_powerline_ps1
localsettings_reformat
PROMPT_COMMAND=do_before_prompt

# When command is not found, fall back to a .sh file if possible
command_not_found_handle() {
    cmd="$1"

    # When command is not found, fallback on scripts
    # If the script name starts with an underscore, it is hidden and thus not listed nor callable
    # Location Priority:
    #   - In current directory
    #   - In ./_lsr_scripts folder
    #   - In ./scripts/ folder
    # Language Priority:
    #   - .sh scripts
    #   - .py scripts
    #   - .js scripts
    #   - npm scripts
    
    # Run the bash script if it exists
    if [[ $cmd != _* ]]; then
        if [[ -f "./$cmd.sh" ]]; then # Run the script
            print_info "Running script $cmd.sh"
            bash "./$cmd.sh" "${@:2}"
            return

        # Run the /_lsr_scripts/ bash script if it exists
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.sh" ]]; then
            print_info "Running script $cmd.sh"
            bash "./_lsr_scripts/$cmd.sh" "${@:2}"
            return

        # Run the /scripts/ bash script if it exists
        elif [[ -d "./scripts" && -f "./scripts/$cmd.sh" ]]; then
            print_info "Running script $cmd.sh"
            bash "./scripts/$cmd.sh" "${@:2}"
            return

        # Run the python script if it exists
        elif [[ -f "./$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./$cmd.py" "${@:2}"
            return

        # Run the /_lsr_scripts/ python script if it exists
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./_lsr_scripts/$cmd.py" "${@:2}"
            return

        # Run the /scripts/ python script if it exists
        elif [[ -d "./scripts" && -f "./scripts/$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./scripts/$cmd.py" "${@:2}"
            return

        # Run the js script if it exists
        elif [[ -f "./$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./$cmd.js" "${@:2}"
            return

        # Run the /_lsr_scripts/ js script if it exists
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./_lsr_scripts/$cmd.js" "${@:2}"
            return

        # Run the /scripts/ js script if it exists
        elif [[ -d "./scripts" && -f "./scripts/$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./scripts/$cmd.js" "${@:2}"
            return

        # Run the script from the npm folder if it exists
        elif [[ -f "./package.json" && "$(grep \"$cmd\": package.json)" != "" ]]; then
            print_info "Running NPM script '$cmd'"
            npm run $cmd --silent
            return
        fi
    fi

    # Command was not found
    suggestions=$(compgen -c "$cmd" | head -n 5)
    if [[ -n "$suggestions" ]]; then
        echo "bash: $cmd: command not found. Did you mean one of these?"
        echo " - $suggestions" | while read -r suggestion; do echo "  $suggestion"; done
    else
        echo "bash: $cmd: command not found"
    fi
    return 127
}

packages() {
    if [[ -f "./package.json" ]]; then
        dependencies=$(jq '.dependencies' package.json)
        if [[ "$dependencies" != "null" && "$dependencies" != "{}" && -n "$dependencies" ]]; then
            echo "Npm packages:"
            jq -r '.dependencies | to_entries | .[] | " - " + .key + " -> " + .value' package.json
            echo ""
        fi
    fi

    if [[ -f "./composer.json" ]]; then
        dependencies=$(jq '.require' composer.json)
        if [[ "$dependencies" != "null" && "$dependencies" != "{}" && -n "$dependencies" ]]; then
            echo "Composer packages:"
            jq -r '.require | to_entries | .[] | " - " + .key + " -> " + .value' composer.json
            echo ""
        fi

        # dev_dependencies=$(jq '.require-dev' composer.json)
        # if [[ "$dev_dependencies" != "null" && "$dev_dependencies" != "{}" && -n "$dev_dependencies" ]]; then
        #     echo "Composer packages (dev):"
        #     jq -r '.require-dev | to_entries | .[] | " - " + .key + " -> " + .value' composer.json
        #     echo ""
        # fi
    fi
}

alias s=scripts
alias ss="select_scripts"

select_scripts() {
    scripts_output=$(scripts)
    scripts_list=$(echo "$scripts_output" | grep '^ - ' | awk '{sub(/^ - /, ""); if (NR > 1) printf ","; printf "%s", $0} END {print ""}')
    
    local value=""
    selectable_list "Select a script" value "$scripts_list"
    $value
}

# Finds scripts to fall back on, in either the current dir, or the ./scripts/ or the ./_lsr_scripts dir.
# If the script name starts with an underscore, it is hidden and thus not listed nor callable
# - bash scripts
# - python scripts
# - nodejs scripts
scripts() {
    if [[ $(find . -maxdepth 1 -wholename "./*.sh" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.sh" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.sh" -print -quit)) ]]; then
        echo "Bash scripts:"
    fi
    for file in ./*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*" && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    for file in ./scripts/*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    for file in ./_lsr_scripts/*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.sh" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.sh" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.sh" -print -quit)) ]]; then
        echo ""
    fi

    if [[ $(find . -maxdepth 1 -wholename "./*.py" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.py" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.py" -print -quit)) ]]; then
        echo "Python scripts:"
    fi
    for file in ./*.py; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.py}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo "- $basename"
        fi
    done
    for file in ./scripts/*.py; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.py}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.py" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.py" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.py" -print -quit)) ]]; then
        echo ""
    fi

    if [[ $(find . -maxdepth 1 -wholename "./*.js" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*js" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.js" -print -quit)) ]]; then
        echo "Node scripts:"
    fi
    for file in ./*.js; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.js}"  # Remove the .js suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo "- $basename"
        fi
    done
    for file in ./scripts/*.js; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.js}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.js" -print -quit)  || ( -d ./scripts && $(find ./scripts -wholename "*.js" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.js" -print -quit)) ]]; then
        echo ""
    fi

    if [[ -f "./package.json" ]]; then
        scripts=$(jq '.scripts' package.json)
        if [[ "$scripts" != "null" && "$scripts" != "{}" && -n "$scripts" ]]; then
            echo "Npm scripts:"
            jq -r ".scripts | \" - \" + keys[]" ./package.json
            echo ""
        fi
    fi
}

lsrdebug() {
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

lsrsilence() {
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

now() {
    local local_settings_file="$HOME/scripts/local_data/local_settings.yml"
    local local_settings_dir="$(dirname "$local_settings_file")"
    local api_key
    local lat
    local lon
    local unconfigured=false

    # Ensure the local_settings directory exists
    mkdir -p "$local_settings_dir"

    # Create an empty local_settings.yml if it doesn't exist
    if [[ ! -f "$local_settings_file" ]]; then
        touch "$local_settings_file"
    fi

    # Function to retrieve weather settings from YAML
    get_weather_settings() {
        # Use yq to extract values from the YAML file
        api_key=$(yq e '.weatherapi.api_key // ""' "$local_settings_file")
        lat=$(yq e '.weatherapi.lat // ""' "$local_settings_file")
        lon=$(yq e '.weatherapi.lon // ""' "$local_settings_file")
        
        # Check if the weatherapi section exists, if not create it
        if [[ -z "$api_key" ]]; then
            yq e -i '.weatherapi.api_key = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.api_key' "$local_settings_file")
            unconfigured=true
        fi

        if [[ -z "$lat" ]]; then
            yq e -i '.weatherapi.lat = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.lat' "$local_settings_file")
            unconfigured=true
        fi

        if [[ -z "$lon" ]]; then
            yq e -i '.weatherapi.lon = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.lon' "$local_settings_file")
            unconfigured=true
        fi

        # Trim any whitespace or quotes from the extracted values
        api_key=$(echo "$api_key" | xargs)
        lat=$(echo "$lat" | xargs)
        lon=$(echo "$lon" | xargs)
    }

    # Get current time in "mm:hh dd/mm/yyyy" format
    local current_time=$(date +"%H:%M %d/%m/%Y")

    # Fetch weather data using the API settings
    get_weather_settings

    if [[ "$unconfigured" == "true" ]]; then
        print_error "Weather API is not configured in settings_data. Configure it with https://openweathermap.org/api\n"
        return 1
    fi
    
    # Call the weather API (OpenWeatherMap in this case)
    local weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$api_key&units=metric")

    # Check if the API returned a valid result
    if [[ -z "$weather_data" ]] || [[ "$(echo "$weather_data" | jq '.cod')" != "200" ]]; then
        print_error "Unable to fetch weather data\n"
        return 1
    fi

    # Parse the weather data using `jq`
    local temp_now=$(echo "$weather_data" | jq '.main.temp')
    local temp_min=$(echo "$weather_data" | jq '.main.temp_min')
    local temp_max=$(echo "$weather_data" | jq '.main.temp_max')
    local humidity=$(echo "$weather_data" | jq '.main.humidity')
    local wind_speed=$(echo "$weather_data" | jq '.wind.speed')
    local weather_condition=$(echo "$weather_data" | jq -r '.weather[0].description')
    local city=$(echo "$weather_data" | jq -r '.name')

    # Define ANSI color codes
    local bold="\033[1m"
    local green="\033[32m"
    local blue="\033[34m"
    local cyan="\033[36m"
    local reset="\033[0m"
    local red="\033[0;31m"
    local yellow='\033[0;33m'

    # Print formatted and colored output
    color_value() {
        local value="$1"
        local low_threshold="$2"
        local mid_threshold="$3"
        local high_threshold="$4"
        local colored_str

        # Use bc for comparisons
        if (( $(echo "$value < $low_threshold" | bc -l) )); then
            colored_str="${blue}${value}${reset}"
        elif (( $(echo "$value >= $low_threshold" | bc -l) && $(echo "$value < $mid_threshold" | bc -l) )); then
            colored_str="${green}${value}${reset}"
        elif (( $(echo "$value >= $mid_threshold" | bc -l) && $(echo "$value < $high_threshold" | bc -l) )); then
            colored_str="${yellow}${value}${reset}"
        else
            colored_str="${red}${value}${reset}"
        fi
        echo "$colored_str"
    }
    
    local temp_now_str=$(color_value "$temp_now" 10 20 25)
    local temp_min_str=$(color_value "$temp_min" 10 20 25)
    local temp_max_str=$(color_value "$temp_max" 10 20 25)
    local wind_speed_str=$(color_value "$wind_speed" 2 5 10)

    echo -e "${bold}${green}Now in $city:${reset}"
    echo -e "${cyan}$current_time${reset}"
    echo -e "Temperature: ${temp_now_str}°C (${temp_min_str}°C - ${temp_max_str}°C)"
    echo -e "Condition: ${weather_condition} (${wind_speed_str} m/s)"
    print_empty_line
}

lhelp() {
    local lhelp_file="$HOME/scripts/lhelp.txt"
    
    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line == \#* ]]; then
            printf "$RED%s$RESET\n" "$line"
        else
            printf "%s\n" "$line"
        fi
        
    done < "$lhelp_file"

    print_empty_line
}

# Ensure tmux is running
setup_tmux_config
tmux source-file ~/.tmux.conf
if [ -z "$TMUX" ]; then
    tmux
fi

alias tu="time_until"
alias tul="time_until_live"

time_until() {
    # Define target times
    target0="8:30:00"
    target1="12:30:00"
    target2="17:00:00"
    
    # Get the current time in seconds since midnight
    local now=$(date +%s)
    
    # Get today's date and convert target times to seconds since midnight
    today=$(date +%Y-%m-%d)
    target0_sec=$(date -d "$today $target0" +%s)
    target1_sec=$(date -d "$today $target1" +%s)
    target2_sec=$(date -d "$today $target2" +%s)

    # Calculate seconds remaining for each target
    passed0=$((now - target0_sec)) # TODO: base this on the first terminal login of the day
    remaining1=$((target1_sec - now))
    remaining2=$((target2_sec - now))

    # Function to convert seconds to hh:mm:ss
    format_time() {
        local seconds=$1
        printf "%02d:%02d:%02d\n" $((seconds/3600)) $(( (seconds%3600)/60 )) $((seconds%60))
    }

    if [ $passed0 -gt 0 ]; then
        echo "Time passed at work: $(format_time $passed0)"
    else
        echo "Work has not started yet"
    fi

    # Display results for both target times
    if [ $remaining1 -gt 0 ]; then
        echo "Time left until break: $(format_time $remaining1)"
    else
        echo "Break time has already passed."
    fi
    
    if [ $remaining2 -gt 0 ]; then
        echo "Time left until End of day: $(format_time $remaining2)"
    else
        echo "End of day has already passed today."
    fi
}

time_until_live() {
    # Define target times
    target1="12:30:00"
    target2="17:00:00"
    
    # Get today's date and convert target times to seconds since midnight
    today=$(date +%Y-%m-%d)
    target1_sec=$(date -d "$today $target1" +%s)
    target2_sec=$(date -d "$today $target2" +%s)
    
    # Function to convert seconds to hh:mm:ss format
    format_time() {
        local seconds=$1
        printf "%02d:%02d:%02d" $((seconds / 3600)) $(((seconds % 3600) / 60)) $((seconds % 60))
    }

    # Continuous loop to update the remaining time every second
    while true; do
        # Get the current time in seconds since midnight
        now=$(date +%s)
        
        # Calculate seconds remaining for each target
        remaining1=$((target1_sec - now))
        remaining2=$((target2_sec - now))

        # Prepare the output strings for each target time
        if [ $remaining1 -gt 0 ]; then
            time_left_1230=$(format_time $remaining1)
        else
            time_left_1230="Already passed"
        fi
        
        if [ $remaining2 -gt 0 ]; then
            time_left_1700=$(format_time $remaining2)
        else
            time_left_1700="Already passed"
        fi

        # Display the remaining time in a single line, overwriting the line each second
        printf "\rTime left until Break: %s | Time left until End of Day: %s" "$time_left_1230" "$time_left_1700"
        
        # Wait for 1 second before updating
        sleep 1
    done
}

alias e=exp
alias eg="exp --go"

exp() {
    local initial_dir="$(pwd)"
    eval "flags=($(composite_help_get_flags "$@"))"

    local go=false
    if composite_help_contains_flag go "${flags[@]}"; then
        go=true
    fi

    while true; do
        lsrlist create dir_items
        lsrlist append dir_items "."
        lsrlist append dir_items ".."

        # Add folders
        for item in *; do
            if [ -d "$item" ]; then
                lsrlist append dir_items "/$item/"
            fi
        done

        # Add files
        for item in *; do
            if [ -f "$item" ]; then
                lsrlist append dir_items "$item"
            fi
        done
        
        selectable_list "$(pwd)" value "$dir_items"

        if [[ "$value" == "." ]]; then
            break;
        fi

        if [[ "$value" == ".." ]]; then
            cd ..;
        fi

        if [[ -f "./$value" ]]; then
            cat "./$value"
            echo ""
            break
        fi

        cd ".$value"
    done
    
    if [[ $go != true ]]; then
        cd "$initial_dir"
    fi
}

copy() {
    local pathToCopy="."
    
    if [ "$#" -gt 0 ]; then
        pathToCopy="$1"
    fi
    
    clear-copy
    mkdir -p "$HOME/.copy"

    # Check if the given path is the current directory
    if [ "$pathToCopy" = "." ]; then
        # If it's the current directory, copy the contents
        cp -r * "$HOME/.copy"
    else
        cp -r "$pathToCopy" "$HOME/.copy"
    fi
}

clear-copy() {
    rm -rf "$HOME/.copy"
}

cut() {
    local pathToCut="."
    if [ ! "$#" -gt 0 ]; then
        pathToCut="."
    fi

    copy "$pathToCut"
    rm -rf "$pathToCut"
}

paste() {
    local target="."
    if [ "$#" -gt 0 ]; then
        target="$1"
    fi

    # Ensure both hidden and non-hidden files are copied
    cp -r "$HOME/.copy"/* "$target"
    cp -r "$HOME/.copy"/.* "$target" 2>/dev/null
}

alias lg="lazygit"

##################################
# Start of LSR module #16        #
# Injected LSR module: cfind.sh  #
# Number of lines: 58            #
# Filesize: 1.63 KB              #
##################################
# Define a list of banned patterns
banned_patterns=(
    "*.exe"
    "*/node_modules/*"
    "*/vendor/*"
    "*.lock"
    "*/.git/*"
    "*.log"
    "*/storage/framework/views/*"
    "*/public/*"
    "*/package-lock.json"
)

RED='\033[0;31m'
RESET='\033[0m'

# Function to check if a file matches any banned pattern
is_banned() {
  local file="$1"
  for pattern in "${banned_patterns[@]}"; do
    # Use double brackets with globbing to allow pattern matching
    if [[ "$file" == $pattern ]]; then
      return 0 # File matches a banned pattern
    fi
  done
  return 1 # File does not match any banned pattern
}

cfind() {
    local query=$1

    if [[ -z $query ]]; then
        echo "Usage: cfind <query string>"
        return 1
    fi

    # Escape special characters in the query for awk
    escaped_query=$(echo "$query" | sed 's/[.*+?[^$()|{}]/\\&/g')

    # Loop through all of the files in the current directory and subdirectories
    find . -type f | while read -r filepath; do
        if ! is_banned "$filepath"; then
            local filename=$(basename "$filepath")
            
            # Use awk to search for the escaped pattern and capture line and column info
            awk -v pattern="$escaped_query" -v fname="$filepath" '
                {
                    # Remove leading whitespace
                    gsub(/^[ \t]+/, "");
                    if ($0 ~ pattern) {
                        # Print filename, line number, column number, and trimmed content
                        printf "\033[0;31m%s:%d:%d\033[0m: %s\n", fname, NR, index($0, pattern), $0
                    }
                }
            ' "$filepath"
        fi
    done
}

####################################
# Start of LSR module #17          #
# Injected LSR module: compile.sh  #
# Number of lines: 157             #
# Filesize: 5.36 KB                #
####################################
source "$HOME/scripts/helpers.sh"

# Global list of scripts to compile
scripts_to_compile=(
    "../helpers"
    "requirementCheck"
    "startup"
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
    "composites/lsr/lsr"
    "composites/utils/list"
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

######################################
# Start of LSR module #18            #
# Injected LSR module: remotelog.sh  #
# Number of lines: 88                #
# Filesize: 2.46 KB                  #
######################################
#!/bin/bash

start_remote_log_catcher_server() {
    PORT="$1"
    URL="$2"
    if [[ -z $1 ]]; then
        PORT=43872
    fi

    # Start the server
    echo "Server running on port $URL, waiting for requests..."

    # Infinite loop to keep the server running
    while true; do
        # Use nc to listen and capture the output into a temporary file
        request=$(nc -l -p "$PORT" -w 1)  # -w 5 means wait for up to 5 seconds for data

        # If no data is received, continue to the next loop
        if [ -z "$request" ]; then
            continue
        fi

        # Extract the body of the request (everything after the blank line)
        body=$(echo "$request" | sed -n '/^\r$/,$p' | tail -n +2)

        # Log the raw body to the console
        print_info "$request"
    done
}

locallog() {
    # Set default port if not provided
    port="$1"
    if [[ -z $1 ]]; then
        port=58473
    fi

    # Start the remote log catcher server
    start_remote_log_catcher_server $port "https://localhost:$port"
}

remotelog() {
    > $LOG_FILE
    local LOG_FILE='./ngrok.log'

    for pid in $(pgrep ngrok); do
        kill -9 $pid
    done

    if ! command -v "ngrok" &> /dev/null; then
        print_error "ngrok must be installed for remotelog. Please install and run ngrok config add-authtoken <token>"
    fi

    # Check if ngrok is already running and kill it
    pgrep ngrok > /dev/null
    if [ $? -eq 0 ]; then
        print_info "ngrok was already running, killing other instance... you can only have one ngrok/remotelog instance running."
        pkill ngrok  # Kill any running ngrok processes
        sleep 1  # Give a moment for the processes to terminate
    fi

    # Set default port if not provided
    port="$1"
    if [[ -z $1 ]]; then
        port=58473
    fi

    print_info "Initializing server..."

    # Start ngrok in the background and redirect both stdout and stderr to the log file
    ngrok http $port --log $LOG_FILE &
    NGROK_PID=$!

    # Wait for ngrok to generate the URL by checking the log file
    while ! grep -q 'https://[a-z0-9\-]*.ngrok-free.app' $LOG_FILE; do
        sleep 1  # Wait until the URL is available in the log
    done

    # Extract the ngrok URL from the log file
    NGROK_URL=$(grep 'https://[a-z0-9\-]*.ngrok-free.app' $LOG_FILE | awk -F"url=" '{print $2}' | awk '{print $1}')

    # Print the ngrok URL
    echo "Your ngrok URL is: $NGROK_URL"

    # Start the remote log catcher server
    start_remote_log_catcher_server $port $NGROK_URL
}


###############################################
# Start of LSR module #19                     #
# Injected LSR module: composites/lsr/lsr.sh  #
# Number of lines: 61                         #
# Filesize: 1.83 KB                           #
###############################################
alias lsr="lsr_main_command"

lsr_main_command() {
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - lsr install"
        echo "  - lsr uninstall"
        echo "  - lsr reinstall"
        echo "  - lsr compile"
        return
    fi

    local command=$1
    shift

    if is_in_list "$command" "status"; then
        lsr_status
    elif is_in_list "$command" "install"; then
        return
    elif is_in_list "$command" "uninstall"; then
        return
    elif is_in_list "$command" "reinstall"; then
        return
    elif is_in_list "$command" "compile"; then
        return
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

    # Check if there's a version history file and if it contains the current version
    if [ -f "$HISTORY_FILE" ]; then
        CURRENT_VERSION=$(yq e '.version_history[-1]' "$HISTORY_FILE" 2>/dev/null)
        if [ ! -z "$CURRENT_VERSION" ]; then
            local_data_installed=true
        fi
    fi

    # Check if both bashrc and version history are present
    if [ "$bashrc_installed" = true ] && [ "$local_data_installed" = true ]; then
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
##################################################
# Start of LSR module #20                        #
# Injected LSR module: composites/utils/list.sh  #
# Number of lines: 42                            #
# Filesize: 883 B                                #
##################################################
# Composite command
lsrlist() {
    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - lsrlist create <listname>"
        echo "  - lsrlist append <listname> <item>"
        echo "  - lsrlist index <listname> <index>"
        return 0
    fi

    local command=$1
    local -n list_ref=$2
    shift
    shift

    if is_in_list "$command" "create"; then
        lsrlist_create list_ref $@
    elif is_in_list "$command" "append"; then
        lsrlist_append list_ref "$@"
    else
        print_error "Command $command does not exist"
        lsrlist # Re-run for help command
    fi
}

lsrlist_append() {
    # echo "aaaaaa: $1"
    # echo "aaaaaa: $2"
    local -n list=$1
    local value="$2"

    if [[ "$list" == "" ]]; then
        list="$value"
    else
        list+=",$value"
    fi
}

lsrlist_create() {
    local -n list=$1
    list=""
}
###################################################
# Start of LSR module #21                         #
# Injected LSR module: composites/docker/dock.sh  #
# Number of lines: 194                            #
# Filesize: 6.43 KB                               #
###################################################
# Define color codes
LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

alias dock="dock_main_command"

# Composite command
dock_main_command() {
    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - dock list"
        echo "  - dock start <index>"
        echo "  - dock stop <index>"
        echo "  - dock delete <index>"
        echo "  - dock restart"
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list,all"; then
        dock_list $@
    elif is_in_list "$command" "start,up,go"; then
        dock_start_project $@
    elif is_in_list "$command" "stop,down,halt"; then
        dock_stop_project $@
    elif is_in_list "$command" "del,delete,rem,remove"; then
        dock_remove_project $@
    elif is_in_list "$command" "restart,start,boot,reboot"; then
        dock_restart $@
    else
        print_error "Command $command does not exist"
        dock_main_command # Re-run for help command
    fi
}

dock_list() {
    echo -e "${BLUE}Container Overview:${RESET}"
    
    # Temporary associative array to store the first container status for each project
    declare -A projects
    declare -A project_status

    # Collect container information and group by project label
    while IFS= read -r container; do
        container_id=$(echo "$container" | awk '{print $1}')
        container_name=$(echo "$container" | awk '{print $2}')
        project_name=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' "$container_id")
        status=$(docker inspect --format '{{.State.Status}}' "$container_id")

        if [[ -n "$project_name" ]]; then
            projects["$project_name"]+="$container_id:$container_name;"
            # Store the status of the first container found for the project
            if [[ -z "${project_status[$project_name]}" ]]; then
                project_status["$project_name"]="$status"
            fi
        fi
    done < <(docker ps -aq)  # Read all container IDs

    # Determine the longest project name
    longest_name=0
    for project in "${!projects[@]}"; do
        length=${#project}
        if (( length > longest_name )); then
            longest_name=$length
        fi
    done

    # Print the headers with dynamic width
    printf "${YELLOW}%-5s\t%-${longest_name}s\t%s\n${RESET}" "Index" "Project Name" "Status"  # Fixed-width headers

    # Print the grouped container information
    local index=1
    for project in "${!projects[@]}"; do
        if [[ "${project_status[$project]}" = "running" ]]; then
            printf "${GREEN}%-5s\t%-${longest_name}s${LIGHT_GREEN}\t%s\n${RESET}" "$index" "$project" "${project_status[$project]}"
        else
            printf "${GREEN}%-5s\t%-${longest_name}s${RED}\t%s\n${RESET}" "$index" "$project" "${project_status[$project]}"
        fi
        
        ((index++))
    done
}

dock_start_project() {
    if [ -z "$1" ]; then
        print_error "Usage: dock start <number>"
        return 1
    fi

    # Collect unique project names in an array
    mapfile -t project_names < <(docker ps -aq --filter "label=com.docker.compose.project" | xargs docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u)

    # Get the project name based on the specified index
    project_name="${project_names[$(( $1 - 1 ))]}"  # Convert to zero-based index

    if [ -z "$project_name" ]; then
        print_error "No project found at index $1."
        return 1
    fi

    # Get the container IDs for the specified project
    container_ids=$(docker ps -aq --filter "label=com.docker.compose.project=$project_name")

    if [ -z "$container_ids" ]; then
        print_error "No stopped containers found for project '$project_name'."
        return 1
    fi

    # Start all containers belonging to the project
    print_success "Starting containers for project: $project_name"
    docker start $container_ids
}

# Stop a Docker container by its index (number)
dock_stop_project() {
    if [ -z "$1" ]; then
        print_error "Usage: dockstop <number>"
        return 1
    fi

    # Get the project name based on the index
    project_name=$(docker ps --format '{{.ID}}' | xargs docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u | sed -n "1p")
    print_debug $project_name
    if [ -z "$project_name" ]; then
        print_error "No project found at index $1."
        return 1
    fi

    # Get the container IDs for the specified project
    container_ids=$(docker ps -q --filter "label=com.docker.compose.project=$project_name")

    if [ -z "$container_ids" ]; then
        print_error "No running containers found for project '$project_name'."
        return 1
    fi

    # Stop all containers belonging to the project
    print_success "Stopping containers for project: $project_name"
    docker stop $container_ids
}

# Remove a Docker container by its index (number)
dock_remove_project() {
    if [ -z "$1" ]; then
        print_error "Usage: dock remove <number>"
        return 1
    fi

    container_ids=$(docker ps -a --format '{{.ID}}' | sed -n "${1}p")  # Get the container ID at the specified index
    if [ -z "$container_ids" ]; then
        print_error "No container found at index $1."
        return 1
    fi

    for container_id in $container_ids; do
        print_success "Removing container: $container_id"
        docker rm "$container_id"
    done
}

dock_restart() {
    # Check if Docker is running
    if docker info >/dev/null 2>&1; then
        print_info "Docker is currently running."
        
        running_containers=$(docker ps -q)
        if [ -n "$running_containers" ]; then
            print_info "Stopping all running containers..."
            docker stop $running_containers
        fi

        print_info "Restarting Docker Desktop..."
        powershell.exe -Command "Get-Process | Where-Object { \$_.Name -like \"*docker*\" } | Stop-Process -Force"
        sleep 5  # Wait for a moment before starting it again
        powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
    else
        print_info "Docker is not running. Starting Docker Desktop..."
        powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
        sleep 20
    fi

    # Confirm the action
    if docker info >/dev/null 2>&1; then
        print_success "Docker is now running."
    else
        print_error "Failed to start Docker."
    fi
}
####################################################
# Start of LSR module #22                          #
# Injected LSR module: composites/git/gitusers.sh  #
# Number of lines: 262                             #
# Filesize: 8.43 KB                                #
####################################################
alias gitusers="git_users_main_command"

# Composite command
git_users_main_command() {
    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - gitusers list"
        echo "  - gitusers get <identifier>"
        echo "  - gitusers new <identifier> <fullname>"
        echo "  - gitusers del <identifier>"
        echo "  - gitusers alias <identifier> <alias>"
        echo "  - gitusers unlias <identifier> <alias>"
        echo "  - gitusers set-initials <identifier> <initials>"
        echo "  - gitusers set-email <identifier> <initials>"
        echo "  - gitusers set-phone <identifier> <initials>"
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list,all"; then
        git_users_list $@
    elif is_in_list "$command" "get"; then
        git_users_get $@
    elif is_in_list "$command" "new,create,add"; then
        git_users_new $@
    elif is_in_list "$command" "del,delete,rem,remove"; then
        git_users_delete $@
    elif is_in_list "$command" "add-alias,new-alias,create-alias,alias,"; then
        git_users_set_alias $@
    elif is_in_list "$command" "del-alias,rem-alias,delete-alias,remove-alias,unalias"; then
        git_users_unset_alias $@
    elif is_in_list "$command" "set-initials"; then
        git_users_set_initials $@
    elif is_in_list "$command" "set-email"; then
        git_users_set_email $@
    elif is_in_list "$command" "set-phone"; then
        git_users_set_phone $@
    else
        print_error "Command $command does not exist"
        git_users_main_command # Re-run for help command
    fi
}

git_users_list() {
    eval "flags=($(composite_help_get_flags "$@"))"

    local INCLUDE_IDENTIFIER=true
    local INCLUDE_FULLNAME=true
    local INCLUDE_ALIASES=false
    local INCLUDE_INITIALS=false
    local INCLUDE_PHONE=false
    local INCLUDE_EMAIL=false
    
    if composite_help_contains_flag aliases "${flags[@]}"; then
        INCLUDE_ALIASES=true
    fi
    if composite_help_contains_flag initials "${flags[@]}"; then
        INCLUDE_INITIALS=true
    fi
    if composite_help_contains_flag phone "${flags[@]}"; then
        INCLUDE_PHONE=true
    fi
    if composite_help_contains_flag email "${flags[@]}"; then
        INCLUDE_EMAIL=true
    fi
    
    lsrlist create headers

    if [[ $INCLUDE_IDENTIFIER == true ]]; then
        lsrlist append headers "Identifier"
    fi
    if [[ $INCLUDE_FULLNAME == true ]]; then
        lsrlist append headers "Full name"
    fi
    if [[ $INCLUDE_ALIASES == true ]]; then
        lsrlist append headers "Aliases"
    fi
    if [[ $INCLUDE_INITIALS == true ]]; then
        lsrlist append headers "Initials"
    fi
    if [[ $INCLUDE_PHONE == true ]]; then
        lsrlist append headers "Phone"
    fi
    if [[ $INCLUDE_EMAIL == true ]]; then
        lsrlist append headers "Email"
    fi

    users=$(localsettings_get .gitusers)
    rows=()

    index=0
    while IFS= read -r user; do
        lsrlist create newRow

        if [[ $INCLUDE_IDENTIFIER == true ]]; then
            lsrlist append newRow "$user"
        fi
        if [[ $INCLUDE_FULLNAME == true ]]; then
            local fullname="$(lsget .gitusers.$user.fullname)"
            lsrlist append newRow "$fullname"
        fi
        if [[ $INCLUDE_ALIASES == true ]]; then
            local aliases="$(lseval ".gitusers.$user.aliases | join(\"\\,\")")"
            lsrlist append newRow "$aliases"
        fi
        if [[ $INCLUDE_INITIALS == true ]]; then
            local initials="$(lseval ".gitusers.$user.initials // \" \"")"
            lsrlist append newRow "$initials"
        fi
        if [[ $INCLUDE_PHONE == true ]]; then
            local phone="$(lseval ".gitusers.$user.phone // \" \"")"
            lsrlist append newRow "$phone"
        fi
        if [[ $INCLUDE_EMAIL == true ]]; then
            local email="$(lseval ".gitusers.$user.email // \" \"")"
            lsrlist append newRow "$email"
        fi

        rows+=("$newRow")
        ((index++))
    done <<< "$(lseval ".gitusers | to_entries | .[] | .key")"

    table "$headers" "${rows[@]}"
}

git_users_get() {
    # Get the needed values
    local identifier=$(prompt_if_not_exists "Identifier" $1)
    
    localsettings_reformat

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    localsettings_eval ".gitusers.\"$identifier\""
}

git_users_new() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\\\"$identifier\\\"")
    if [[ ! "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier already exists"
        return 1
    fi

    local fullname=$(prompt_if_not_exists "Fullname" $2)

    # Set the values to the local settings
    localsettings_eval_with_save ".gitusers.\"$identifier\".fullname = \"$fullname\"" > /dev/null
    localsettings_eval_with_save ".gitusers.\"$identifier\".aliases = [ \"$fullname\" ]" > /dev/null
    localsettings_reformat
    print_success "Created gituser \"$identifier\""
}

git_users_delete() {
    # Get the needed values
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if not exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exists"
        return 1
    fi

    localsettings_delete ".gitusers.\"$identifier\""
    print_success "Deleted gituser \"$identifier\""
}

git_users_set_alias() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local alias=$(prompt_if_not_exists "Alias" $2)

    localsettings_eval_with_save ".gitusers.\"$identifier\".aliases += [ \"$alias\" ]"

    print_success "Added alias '$alias' to gituser '$identifier'"

    localsettings_reformat
}

git_users_unset_alias() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local alias=$(prompt_if_not_exists "Alias" $2)

    localsettings_eval_with_save "del(.gitusers.\"$identifier\".aliases[] | select(. == \"$alias\"))"

    print_success "Deleted alias '$alias' to gituser '$identifier'"

    localsettings_reformat
}

git_users_set_initials() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local initials=$(prompt_if_not_exists "Initials" $2)
    localsettings_eval_with_save ".gitusers.\"$identifier\".initials = \"$initials\""
    print_success "Updated initials for gituser '$identifier'"
    localsettings_reformat
}

git_users_set_phone() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local phone=$(prompt_if_not_exists "phone" $2)
    localsettings_eval_with_save ".gitusers.\"$identifier\".phone = \"$phone\""
    print_success "Updated phone for gituser '$identifier'"
    localsettings_reformat
}

git_users_set_email() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local email=$(prompt_if_not_exists "email" $2)
    localsettings_eval_with_save ".gitusers.\"$identifier\".email = \"$email\""
    print_success "Updated email for gituser '$identifier'"
    localsettings_reformat
}
####################################################
# Start of LSR module #23                          #
# Injected LSR module: composites/git/branches.sh  #
# Number of lines: 154                             #
# Filesize: 4.51 KB                                #
####################################################
alias branches="git_branches_main_command"

# Composite command
git_branches_main_command() {
    local filter=""
    local argument_count=$#
    local defined_commands=(
        "branches list"
        "branches list feature"
        "branches go <branch-name>"
        "branches feature new <feature-name>"
        "branches feature delete <feature-name>"
        "branches feature go <feature-name>"
    )

    # composite_help_command "$filter" $argument_count "${defined_commands[@]}"

    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - branches list"
        echo "  - branches list feature"
        echo "  - branches go <branch-name>" # TODO

        echo "  - branches feature new <feature-name>"
        echo "  - branches feature delete <feature-name>"
        echo "  - branches feature go <feature-name>" # TODO
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list"; then
        local command=$1
        shift

        if [[ -z $command ]]; then
            git_branches_list $@
        elif is_in_list "$command" "feature"; then
            git_branches_list_features $@
        else
            print_error "Command 'branches list $command' does not exist"
            git_branches_main_command # Re-run for help command
        fi
    elif is_in_list "$command" "go"; then
        git_branches_go $@
    elif is_in_list "$command" "feature"; then
        local command=$1
        shift

        if is_in_list "$command" "new"; then
            git_branches_features_new $@
        elif is_in_list "$command" "delete"; then
            git_branches_features_delete $@
        elif is_in_list "$command" "go"; then
            git_branches_features_go $@
        else
            print_error "Command 'branches feature $command' does not exist"
            git_branches_main_command # Re-run for help command
        fi
    else
        print_error "Command 'branches $command' does not exist"
        git_branches_main_command # Re-run for help command
    fi
}

git_branches_features_go() {
    local featureName=$1

    if [[ -z $featureName ]]; then
        print_error "'branches feature go' expects an argument for the feature-name\nUsage: branches feature go <feature-name>"
        return 1
    fi

    local featureBranchName="feature/$featureName"

    if ! git_branch_exists $featureBranchName; then
        print_error "Branch $featureBranchName does not exist locally or remotely"
        return
    fi

    git checkout $featureBranchName &>/dev/null
    print_success "Switched to branch $featureBranchName"
}

git_branches_features_delete() {
    local featureName=$1

    if [[ -z $featureName ]]; then
        print_error "'branches feature delete' expects an argument for the feature-name\nUsage: branches feature delete <feature-name>"
        return 1
    fi

    local featureBranchName="feature/$featureName"

    if ! git_branch_exists $featureBranchName; then
        print_error "Branch $featureBranchName does not exist locally or remotely"
        return
    fi

    read_info "Deleting branch $featureBranchName, are you sure? (y/n): " confirm

    if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
        print_info "Branch deletion cancled..."
        return
    fi

    git checkout development &>/dev/null
    git branch --delete $featureBranchName &>/dev/null
    print_success "Deleted branch $featureBranchName"
}

git_branches_features_new() {
    local featureName=$1

    if [[ -z $featureName ]]; then
        print_error "'branches feature new' expects an argument for the feature-name\nUsage: branches feature new <feature-name>"
        return 1
    fi

    local featureBranchName="feature/$featureName"
    print_info "Creating branch $featureBranchName..."

    git checkout develop &>/dev/null
    git branch $featureBranchName &>/dev/null
    git checkout $featureBranchName &>/dev/null

    print_success "Branch $featureBranchName was created succesfully"
}

git_branches_go() {
    local branchName=$1

    if [[ -z $branchName ]]; then
        print_error "'branches go' expects an argument for the branch-name\nUsage: branches feature go <branch-name>"
        return 1
    fi

    if ! git_branch_exists $branchName; then
        print_error "Branch $branchName does not exist locally or remotely"
        return
    fi

    git checkout $branchName &>/dev/null
    print_success "Switched to branch $branchName"
}

git_branches_list_features() {
    git branch --all | grep " feature/" --color=never
}

git_branches_list() {
    git branch --all --no-color
}
########################################################
# Start of LSR module #24                              #
# Injected LSR module: composites/settings/profile.sh  #
# Number of lines: 159                                 #
# Filesize: 4.54 KB                                    #
########################################################
local_settings_file="$HOME/scripts/local_data/local_settings.yml"
local_settings_dir="$(dirname "$local_settings_file")"

alias profile="profile_main_command"

# Composite command
profile_main_command() {
    reset_ifs

    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - profile current"
        echo "  - profile list"
        echo "  - profile load <identifier>"
        echo "  - profile save <identifier>"
        echo "  - profile edit <identifier>"  # TODO
        echo "  - profile rename <old identifier> <new identifier>"  # TODO
        echo "  - profile delete <identifier>"  # TODO
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list"; then
        profile_list $@
    elif is_in_list "$command" "current"; then
        profile_current $@
    elif is_in_list "$command" "load"; then
        profile_load $@
    elif is_in_list "$command" "save"; then
        profile_save $@
    elif is_in_list "$command" "edit"; then
        profile_edit $@
    elif is_in_list "$command" "delete"; then
        profile_delete $@
    else
        print_error "Command $command does not exist"
        profile_main_command # Re-run for help command
    fi
}

profile_delete() {
    local current_profile="$(profile current)"

    # Get the profile name
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile delete <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1

    if [[ "$current_profile" == "$profile" ]]; then
        print_error "Cant delete current profile"
        return 1
    fi

    # Make sure new profile exist
    if [[ ! -f "$local_settings_dir/local_settings.$profile.yml" ]]; then
        print_error "Profile '$profile' doesnt exist"
    fi

    rm "$local_settings_dir/local_settings.$profile.yml"
}

profile_select() {
    profile_output=$(profile_list)
    profile_list=$(echo "$profile_output" | grep '^ - ' | awk '{sub(/^ - /, ""); if (NR > 1) printf ","; printf "%s", $0} END {print ""}')
    
    local value=""
    selectable_list "Select a profile" value "$profile_list"
    profile load $value
}

profile_load() {
    # Get the profile name
    if [ "$#" -ne 1 ]; then
        profile_select
        return 0  # Return an error code
    fi
    local profile=$1

    # Make sure new profile exist
    if [[ ! -f "$local_settings_dir/local_settings.$profile.yml" ]]; then
        print_error "Profile '$profile' doesnt exist"
    fi

    # Load it
    cp "$local_settings_dir/local_settings.$profile.yml" "$local_settings_dir/local_settings.yml"
    print_success "Loaded profile local_settings.$profile.yml"
}

profile_save() {
    # Get the profile name
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile save <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1
    local current_profile="$(profile_current)"

    # Set current profile name
    lsset profile $profile &> /dev/null

    # If new profile already exists and is different from current profile,
    # Dont allow, since this will overwrite an existing profile
    if [[ -f "$local_settings_dir/local_settings.$profile.yml" && $profile != $current_profile ]]; then
        print_error "Aborting since this will overwrite existing profile '$profile'"
        return 1
    fi

    # Save it
    cp "$local_settings_dir/local_settings.yml" "$local_settings_dir/local_settings.$profile.yml"
    print_success "Saved current profile to local_settings.$profile.yml"
}

profile_edit() {
    # Get the profile name
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile save <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1
    echo "profile => $local_settings_dir/local_settings.$profile.yml"

    if [[ ! -f "$local_settings_dir/local_settings.$profile.yml" ]]; then
        print_error "Profile '$profile' does not exist"
        return 1
    fi

    nano "$local_settings_dir/local_settings.$profile.yml"
}

profile_list() {
    echo "Profiles: "
    for file in $local_settings_dir/local_settings*.yml; do
        if [ -f "$file" ]; then
            local file_name="$(basename "$file")"
            local profile_name="$(echo "$file_name" | sed 's/^local_settings.\(.*\).yml$/\1/')"
            
            if [[ "$profile_name" == "local_settings.yml" ]]; then
                continue
            fi
            
            echo " - $profile_name"
        fi
    done
}

profile_current() {
    local profile="$(localsettings_get .profile)"

    if [[ "$profile" == "null" ]]; then
        profile="default"
        lsset profile "$profile" &> /dev/null
    fi

    echo "$profile"
}
