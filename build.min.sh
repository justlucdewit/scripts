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
ensure_sudo() {
    if ! sudo -l &> /dev/null; then
        print_info "Requesting sudo access..."
        
        sudo -v
        if [ $? -ne 0 ]; then
            print_error "This script requires sudo privileges. Please run with sudo."
            exit 1  # Exit if the user does not have sudo privileges
        fi
        print_info "Sudo access granted."
    fi
}
install_if_not_exist() {
    local command_name=$1
    local test_command_name=$2
    if [[ -z $test_command_name ]]; then
        test_command_name=$command_name
    fi
    if ! command -v "$test_command_name" &> /dev/null; then
        print_info "$command_name is not installed. Attempting to install..."
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
requires_package "yq" "LSR"
requires_package "jq" "LSR"
requires_package "node" "LSR"
requires_package "npm" "LSR"
requires_package "git" "LSR"
CUSTOM_CONFIG="$HOME/scripts/extra_config_files/lsr.gitconfig"
GLOBAL_CONFIG="$HOME/.gitconfig"
if [ ! -f "$GLOBAL_CONFIG" ]; then
    touch "$GLOBAL_CONFIG"
fi
if ! grep -q "$CUSTOM_CONFIG" "$GLOBAL_CONFIG"; then
    echo -e "\n[include]\n\tpath = $CUSTOM_CONFIG" >> "$GLOBAL_CONFIG"
fi
GLOBAL_GITIGNORE="$HOME/scripts/extra_config_files/lsr.gitignore"
if ! grep -q "lsr.gitignore" "$GLOBAL_CONFIG"; then
    cat <<EOL >> $GLOBAL_CONFIG
[core]
    excludesfile = $GLOBAL_GITIGNORE
EOL
fi
composite_help_get_flags() {
    reset_ifs
    local flags=()
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
    echo "${flags[@]}"
}
composite_help_get_rest() {
    reset_ifs
    local non_flags=()
    for arg in "$@"; do
        if [[ (! "$arg" =~ ^--) && (! "$arg" =~ ^-) ]]; then
            non_flags+=("\"$arg\"")
        fi
    done
    echo "${non_flags[@]}"
}
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
        if [[ "$flag" == "--$flagName="* ]]; then
            value="${flag#*=}"  # Extract everything after the '='
            echo "$value"        # Output the value to the caller
            return 0             # Success
        fi
        if [[ "$flag" == "--$flagName" ]]; then
            echo "true"          # For flags like --flag without a value
            return 0             # Success
        fi
    done
    return 1  # Flag not found
}
composite_help_flag_get_value() {
    flagName=$1
    shift
    flags=("$@")
    for flag in "${flags[@]}"; do
        if [[ "$flag" == "$flagName"* ]]; then
            value="${flag#*=}"
            echo "$value"
            return
        fi
    done
    echo ""
}
composite_help_command() {
    
    local filter=$1               # Filter for what help commands to show
    local argument_count=$2       # Number of arguments
    shift 2
    echo "$2"
    return
    local defined_commands=("$@")  # List of commands
    if [ "$argument_count" -gt 0 ]; then
        return
    fi
    echo "Usage: '${defined_commands[@]}' "
    for cmd in "${defined_commands[@]}"; do
        echo " - $cmd"
            
    done
}
alias gitusers="git_users_main_command"
git_branch_exists() {
    branchName="$1"
    local localBranches
    localBranches=$(git branch --list "$branchName")
    if [[ -n "$localBranches" ]]; then
        return 0  # Branch exists locally
    fi
    local remoteBranches
    remoteBranches=$(git branch --all | grep -w "remotes/origin/$branchName")
    if [[ -n "$remoteBranches" ]]; then
        return 0  # Branch exists remotely
    fi
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
alias delete='git branch -d'
alias d="!f() { git branch -d $1 && git push origin --delete $1; }; f"
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
    if [[ ! "$pane_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Pane number must be a number."
        return 1
    fi
    local pane_id=$(tmux list-panes -F "#{pane_index} #{pane_id}" | awk -v num="$pane_number" '$1 == num {print $2}'  | tr -d '%')
    if [ -z "$pane_id" ]; then
        echo "No pane found with number: $pane_number"
        return 1
    fi
    echo "$pane_id"
}
get_pane_number() {
    if [ -z "$1" ]; then
        echo "Usage: get_pane_number <pane_id_without_percentage>"
        return 1
    fi
    local pane_id="$1"
    
    if [[ ! "$pane_id" =~ ^[0-9]+$ ]]; then
        echo "Error: Pane ID must be a number."
        return 1
    fi
    local pane_index=$(tmux list-panes -F "#{pane_id},#{pane_index}" | grep "%${pane_id}" | cut -d',' -f2)
    if [ -z "$pane_index" ]; then
        echo "No pane found with ID: %$pane_id"
        return 1
    fi
    echo "$pane_index"
}
debug_message() {
    if [[ "$DEBUG_CACHE_WRITING" = true ]]; then
        print_debug "$1"
    fi
}
declare -gA pane_names
set_stored_pane_name() {
    local key="$1"
    local value="$2"
    pane_names["$key"]="$value"
}
sync_pane_names() {
    debug_message "SYNCING PANE NAMES..."
    
    declare -A old_pane_names 
    for key in "${!pane_names[@]}"; do
        old_pane_names["$key"]="${pane_names[$key]}"
    done
    unset pane_names
    declare -gA pane_names
    load_pane_names
    sessions=$(tmux list-sessions -F '#S')  # Get all session names
    for session in $sessions; do
        current_windows=$(tmux list-windows -t "$session" -F '#I')  # Get window indices for each session
        for window in $current_windows; do
            panes=$(tmux list-panes -t "$session:$window" -F '#D')
            for pane in $panes; do
                pane_key="$session:$window:$pane"
                if [[ -z "pane_names[$pane_key]" ]]; then
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
    
    if [ ${#pane_names[@]} -eq 0 ]; then
        echo "No named panes found."
        return
    fi
    for key in "${!pane_names[@]}"; do
        echo "$key: ${pane_names[$key]}"
    done
}
load_pane_names() {
    debug_message "LOADING PANE NAMES..."
    if [[ ! -f "$PANE_NAME_FILE" ]]; then
        return
    fi
    unset pane_names
    declare -gA pane_names
    while IFS=':' read -r session window pane name; do
        if [[ -n "$session" && -n "$window" && -n "$pane" && -n "$name" ]]; then
            pane_names["$session:$window:$pane"]="$name"
        else
            echo "Skipping malformed line: '$session:$window:$pane:$name'"
        fi
    done < "$PANE_NAME_FILE"
}
save_pane_names() {
    debug_message "SAVING PANE NAMES..."
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
alias wr="tmux select-window -t +1" # Move a window right
alias wl="tmux select-window -t -1" # Move a window left
alias wn="tmux new-window" # New window
alias wk="tmux kill-window" # Close window
alias rw="rename_window" # Rename window
alias sr="tmux rename-session"
alias sl=""
alias sn="tmux new-session"
alias sc="tmux kill-session"
alias sw=""
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
        pane_name=$1
        current_pane=$(tmux display-message -p '#D' | tr -d '%')  # Get the current pane id
    elif [[ $# -eq 2 ]]; then
        current_pane=$(get_pane_id $1)
        echo "going for pane $target_pane"
        pane_name=$2
    else
        echo "Usage: rename_pane [<pane_number>] <new_name>"
        return 1
    fi
    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')
    pane_key="${current_session}:${current_window}:${current_pane}"
    old_name=${pane_names[$pane_key]:-"Unnamed Pane"}
    pane_names[$pane_key]="$pane_name"
    save_pane_names
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
    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')
    current_pane_id=$(tmux display -p '#D' | tr -d '%')  # Unique pane ID
    pane_key="${current_session}:${current_window}:${current_pane_id}"
    current_pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}
    echo -e "${ACTIVE_LIST_ITEM}Session $current_session: \e[1;34m$current_session\e[0m"
    echo -e "${INDENT}${ACTIVE_LIST_ITEM}\e[1;32mWindow $current_window: Window $current_window\e[0m"
    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $current_pane_id: $current_pane_name\e[0m"
}
tlist() {
    load_pane_names
    sync_pane_names
    active_session=$(tmux display-message -p '#S')
    active_window=$(tmux display-message -p '#I')
    active_pane=$(tmux display-message -p '#D' | tr -d '%')
    tmux list-sessions -F '#S' | nl -w1 -s': ' | while read session; do
        session_number=$(echo "$session" | cut -d':' -f1 | xargs)  # Get the session number
        session_name=$(echo "$session" | cut -d':' -f2 | xargs)    # Get the session name
        if [ "$session_name" == "$active_session" ]; then
            echo -e "${ACTIVE_LIST_ITEM}\e[1;34mSession $session_number: $session_name\e[0m"
        else
            echo -e "${INACTIVE_LIST_ITEM}\e[1;34mSession $session_number: $session_name\e[0m"
        fi
        tmux list-windows -t "$session_name" -F '#I: #W' | while read -r window; do
            window_number=$(echo "$window" | cut -d':' -f1 | xargs)  # Get the window number
            window_name=$(echo "$window" | cut -d':' -f2 | xargs)    # Get the window name
            if [ "$session_name" == "$active_session" ] && [ "$window_number" == "$active_window" ]; then
                echo -e "${INDENT}${ACTIVE_LIST_ITEM}\e[1;32mWindow $window_number: $window_name\e[0m"
            else
                echo -e "${INDENT}${INACTIVE_LIST_ITEM}\e[1;32mWindow $window_number: $window_name\e[0m"
            fi
            tmux list-panes -t "$session_name:$window_number" -F '#D: #T' | while read -r pane; do
                pane_id=$(echo "$pane" | cut -d':' -f1 | xargs | tr -d '%')  # Get the pane number
                pane_number=$(get_pane_number $pane_id)
                pane_key="${session_name}:${window_number}:${pane_id}"
                pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}
                if [ "$session_name" == "$active_session" ] && [ "$window_number" == "$active_window" ] && [ "$pane_id" == "$active_pane" ]; then
                    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $pane_id($pane_number): $pane_name\e[0m"
                else
                    echo -e "${INDENT}${INDENT}${INACTIVE_LIST_ITEM}\e[1;33mPane $pane_id($pane_number): $pane_name\e[0m"
                fi
            done
        done    
    done
}
resize_up() {
    local size=  # Default to 5 if no argument is provided
    
}
run_in_pane() {
    load_pane_names
    local current_pane=$(tmux display-message -p '#D')
    
    local target_pane=$1
    shift
    
    local command="$*"
    tmux send-keys -t $target_pane "$command" C-m
}
run_in_pane_until_finished() {
    load_pane_names
    local target_pane=$1
    shift
    local command="$*"
    tmux send-keys -t $target_pane "$command" C-m
    while true; do
        local pane_output=$(tmux capture-pane -pt $target_pane -S - )
        if [[ $pane_output =~ \$$  ]]; then  # Example: match shell prompt ending with "$ "
            break
        fi
        sleep 1
    done
}
alias tcur="tmux display-message -p 'Current pane number: #D'"
t() {
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
setup_tmux_config() {
    local tmuxconfig_file="$HOME/.tmux.conf"
    cp ~/scripts/extra_config_files/.tmux.conf ~/.tmux.conf
}
alias tca="tcloseall"
alias rip="run_in_pane"
alias ripuf="run_in_pane_until_finished"
alias tc="tclose"
table() {
    local header_csv="$1"
    IFS=',' read -r -a headers <<< "$header_csv"
    local colCount="${#headers[@]}"
    local colLengths=()
    for header in "${headers[@]}"; do
        local headerLength="${#header}"
        colLengths+=("$headerLength")
    done
    shift
    for row in "${@:1}"; do
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
    for ((i = 0; i < ${#headers[@]}; i++)); do
        local header="${headers[i]}"
        local headerLength="${colLengths[i]}"
        local currHeaderLength="${#header}"
        echo -n "│ $header"
        echo -n "$(printf ' %.0s' $(seq 1 $(( headerLength - currHeaderLength + 1 ))))"
    done
    echo "│"
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
    for row in "${@:1}"; do
        
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
    print_menu() {
        clear
        echo "Use Arrow Keys to navigate, Enter to select:"
        list "$title" "$options_list" "--selected=${options[$selected]}" --selected-prefix="\e[1;32m => " --prefix="\e[0m  - "
        echo -ne "\e[0m"
    }
    while true; do
        print_menu
        read -rsn1 input
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
new_project() {
    local project_name="$1"
    local project_dir="$2"
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    if [[ -z "$project_name" ]]; then
        echo "Usage: nproject <project_name> [project_directory]"
        return 1
    fi
    if [[ -z "$project_dir" ]]; then
        project_dir="."  # Convert to lowercase and set a default directory
    fi
    project_dir=$(realpath -m "$project_dir" 2>/dev/null) || project_dir="$(cd "$project_dir" && pwd)"
    if [[ -f "$yaml_file" ]]; then
        if [[ $(yq eval ".projects | has(\"$project_name\")" "$yaml_file") == "true" ]]; then
            echo "Project '$project_name' already exists in local_settings."
        else
            yq eval -i ".projects.$project_name = {\"dir\": \"$project_dir\", \"url\": null}" "$yaml_file"
            echo "Added project '$project_name' to local_settings."
        fi
        localsettings_reformat
    else
        echo "YAML file not found: $yaml_file"
    fi
}
remove_project() {
    local project_name="$1"
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    if [[ -z "$project_name" ]]; then
        echo "Usage: premove <project_name>"
        return 1
    fi
    if [[ -f "$yaml_file" ]]; then
        if [[ $(yq eval ".projects | has(\"$project_name\")" "$yaml_file") == "true" ]]; then
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
    if [[ -n "$1" ]]; then
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
        list_projects "$show_dirs"  # Pass the option to list_projects
    fi
}
current_project() {
    local cwd
    cwd=$(pwd | xargs)  # Get the current working directory
    local project_list
    project_list=$(proj --dirs 2>/dev/null | sed '1d')  # Suppress errors and output
    while IFS= read -r line; do
        local project_name
        local project_path
        project_name=$(echo "$line" | awk -F ': ' '{print $1}' | sed 's/\x1B\[[0-9;]*m//g')
        project_path=$(echo "$line" | awk -F ': ' '{print $2}' | sed 's/\x1B\[[0-9;]*m//g')
        project_path=$(echo "$project_path" | xargs)
        if [[ "$cwd" == "$project_path" ]]; then
            echo "$project_name" | awk -F ' - ' '{print $2}'  # Return the project name if it matches
            return 0
        fi
    done <<< "$project_list"
    return 1
}
load_yaml_projects() {
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    declare -gA yaml_projects=()  # Temporary array to store YAML projects
    if [[ -f "$yaml_file" ]]; then
        
        
        while IFS="=" read -r key value; do
            
            key=$(echo "$key" | xargs)    # Trim whitespace
            value=$(echo "$value" | xargs) # Trim whitespace
            if [[ "$value" == "~"* ]]; then
                value="${HOME}${value:1}"  # Replace ~ with $HOME
            fi
            yaml_projects["$key"]="$value"
        done < <(lseval ".projects | to_entries | .[] | .key + \"=\" + .value.dir")
    fi
}
list_projects() {
    load_yaml_projects
    local current_dir=$(pwd)
    local green='\033[0;32m'
    local reset='\033[0m'
    echo "Available projects:"
    local show_dirs="$1"
    for key in "${!yaml_projects[@]}"; do
        if [[ "${yaml_projects[$key]}" == "$current_dir" ]]; then
            if [[ "$show_dirs" == true ]]; then
                echo -e "${green} - $key: ${yaml_projects[$key]}${reset}"
            else
                echo -e "${green} - $key${reset}"  # Green highlight for the project name
            fi
        else
            if [[ "$show_dirs" == true ]]; then
                echo " - $key: ${yaml_projects[$key]}"
            else
                echo " - $key"
            fi
        fi
    done
}
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
alias fresh="fresh_install_sail"
npmscripts() {
    local path="package.json"
    
    if [ ! -f "$path" ]; then
        echo "Error: $path not found."
        return 1
    fi
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
    local priority_order=("watch" "dev" "start")
    local scripts
    scripts=$(jq -r '.scripts | to_entries[] | .key' package.json)
    for script in "${priority_order[@]}"; do
        if echo "$scripts" | grep -q "^$script$"; then
            echo "$script"
            return 0
        fi
    done
    echo "No matching npm scripts found."
    return 1  # Exit with error if no matching scripts are found
}
create_start_layout() {
    local current_project="$(cproj)"
    if [[ $current_project == "" ]]; then
        print_error "Cannot start project because current dir is not a laravel project configured in proj"
        return 1
    fi
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
    if [[ -z $project ]]; then
        echo "Usage: switch <projectname>"
        return 0
    fi
    local failedSwitching=$(proj "$project" | grep -q "Project not found. Available projects:" && echo true || echo false)
    if [[ $failedSwitching == true ]]; then
        print_error "Cannot switch to project '$project' because it does not exist"
        proj
        return 1
    fi
    stop
    start $project
}
stop() {
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
    local project=$1
    local failedSwitching=$(proj "$project" | grep -q "Project not found. Available projects:" && echo true || echo false)
    if [[ $failedSwitching == true ]]; then
        print_error "Cannot start project '$project' because it does not exist"
        proj
        return 1
    fi
    if [[ -n "$project" ]]; then
        proj "$project"
    else # No project was given
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
    npm_script=$(get_first_npm_script)
    if grep -q "\"$npm_script\": \"vite" package.json; then
        print_info "starting npm with 'npm run $npm_script -- --no-open'"
        run_in_pane 1 "npm run $npm_script -- --no-open"
    else
        print_info "starting npm with 'npm run $npm_script'"
        run_in_pane 1 "npm run $npm_script"
    fi
    local projurl=$(get_project_url)
    if [[ "$projurl" == "null" ]]; then
        print_info "starting sail..."
        run_in_pane 0 sail up
    else
        run_in_pane 2 "(sleep 5; explorer.exe $projurl) &" 
        print_info "starting sail..."
        run_in_pane 0 sail up
    fi
    return 0
}
fresh_install_sail() {
    if [[ "$1" == "--remove-docker-image" ]]; then
        if [[ $(docker ps -aq -f "name=your_container_name") ]]; then
            ./vendor/bin/sail down --rmi all --volumes
            print_success "Docker containers, images, and volumes removed."
        else
            print_error "No Docker container found to remove."
        fi
    fi
    if [ -d "vendor" ]; then
        rm -rf vendor
        print_success "Removed vendor directory."
    else
        print_info "No vendor directory found."
    fi
    if [ -d "node_modules" ]; then
        rm -rf node_modules
        print_success "Removed node_modules directory."
    else
        print_info "No node_modules directory found."
    fi
    composer install
    print_success "PHP dependencies installed."
    npm install
    print_success "JavaScript dependencies installed."
    if [[ "$1" == "--remove-docker-image" ]]; then
        ./vendor/bin/sail create
        print_success "Docker containers created."
    else
        ./vendor/bin/sail build
        print_success "Docker containers built."
    fi
}
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
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi
    local value=$(yq e "$field // \"\"" "$local_settings_file")
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
    while getopts "auh" opt; do
        case "$opt" in
            a) allow_create=true ;;
            u) unquoted=true ;;
            h) show_help; return 0 ;;
            \?) print_normal "Invalid option: -$OPTARG" >&2; return 1 ;;
            :) print_normal "Option -$OPTARG requires an argument." >&2; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))
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
    if [[ -z "$field" || -z "$value" ]]; then
        print_normal "Error: FIELD and VALUE are required." >&2
        return 1
    fi
    if [[ "$field" != .* ]]; then
        field=".$field"
    fi
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi
    if $allow_create; then
        localsettings_ensureexists "$field"
    fi
    print_normal "$unquoted"
    if [[ $unquoted == "true" ]]; then
        print_normal "YEEE"
        print_normal "yq e -i \"$field=$value\" \"$local_settings_file\""
        yq e -i "$field=$value" "$local_settings_file"
    else
        yq e -i "$field=\"$value\"" "$local_settings_file"
    fi
}
yq_validate_only_lookup() {
    local field="$1"
    if [[ "$field" == "." ]]; then
        return 0  # Valid case for root access
    fi
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
source ~/scripts/helpers.sh
BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
SETTINGS_FILE=~/scripts/_settings.yml
HISTORY_FILE=~/scripts/local_data/version_history.yml
alias lstatus=lsr_status
alias linstall=lsr_install
alias lreinstall=lsr_reinstall
alias luninstall=lsr_uninstall
lsr_status() {
    local bashrc_installed=false
    local local_data_installed=false
    if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        bashrc_installed=true
    fi
    if [ -f "$HISTORY_FILE" ]; then
        CURRENT_VERSION=$(yq e '.version_history[-1]' "$HISTORY_FILE" 2>/dev/null)
        if [ ! -z "$CURRENT_VERSION" ]; then
            local_data_installed=true
        fi
    fi
    if [ "$bashrc_installed" = true ] && [ "$local_data_installed" = true ]; then
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
    if [[ -f "$HISTORY_FILE" ]]; then
        rm "$HISTORY_FILE"
        print_info "Deleted version history file"
    fi
    if grep -q "^$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        sed -i "/^$BASHRC_STARTER/,/^$BASHRC_ENDERER/d" "$BASHRC_PATH"
        print_info "Removed LSR loader from $BASHRC_PATH"
    fi
    print_empty_line
    print_info "LSR has been reinstalled"
    print_info " - linstall to undo"
    print_info " - Open new session to confirm"
    reload_bash
}
setup_vim_plug() {
    local vim_autoload_dir="$HOME/.vim/autoload"
    local plug_file="$vim_autoload_dir/plug.vim"
    if [ ! -d "$vim_autoload_dir" ]; then
        mkdir -p "$vim_autoload_dir"
        print_info "Created directory: $vim_autoload_dir"
    fi
    if [ ! -f "$plug_file" ]; then
        curl -fLo "$plug_file" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        print_info "Downloaded vim-plug to $plug_file"
    fi
}
write_to_vimrc() {
    local vimrc_file="$HOME/.vimrc"
    setup_vim_plug
    local vimrc_text="
source ~/scripts/extra_config_files/LukesVimConfig.vim
"
    echo "$vimrc_text" > "$vimrc_file"
}
write_to_vimrc
work() {
    local date="$(date --date='yesterday' +%Y-%m-%d)"
    local filter_user=""
    local filter_project=""
    local original_pwd=$(pwd)
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
    date=$(date --date="$date" +%Y-%m-%d)
    echo -e "\n\033[34mSearching for commits on $date in all projects"
    reset_ifs
    for repo in $(localsettings_eval ".projects[] | .dir"); do # Go through all of the projects
        if [ -d "$repo/.git" ]; then # If they are git repos
            cd "$repo" || continue
            
            local projectlabel=$(localsettings_eval "(.projects | to_entries | map(select(.value.dir == \"$repo\")))[0].key")
            if [[ -n "$filter_project" && "$filter_project" != "$projectlabel" ]]; then
                continue;
            fi
            echo -e "\n\033[36m=== $projectlabel ===\033[0m"
            
            git fetch --all >/dev/null 2>&1
            commits=$(git log --all --remotes --branches --since="$date 00:00" --until="$date 23:59" --pretty=format:"%H|%an|%ae|%s|%ad" --date=iso --reverse)
            local found_commits=false
            if [ -n "$commits" ]; then
                while IFS='|' read -r commit_hash username email commit_message commit_date; do
                    local gituser=$(find_git_user_by_alias "$username")
                    local gituser_identifier=$(echo "$gituser" | yq e '.identifier' -)
                    
                    local lower_username="$(echo "$username" | tr '[:upper:]' '[:lower:]')"
                    local lower_identifier="$(echo "$gituser_identifier" | tr '[:upper:]' '[:lower:]')"
                    local lower_filter_user="$(echo "$filter_user" | tr '[:upper:]' '[:lower:]')"
                    if [[ -n "$filter_user" && "$lower_filter_user" != "$lower_identifier" && "$lower_username" != "$lower_filter_user" ]]; then
                        continue
                    fi
                    
                    found_commits=true
                    
                    time=$(date -d "$commit_date" +%H:%M)
                    if [[ $gituser_identifier != "null" ]]; then
                        username=$gituser_identifier
                    fi
                    echo -e "\033[32m$username\033[0m@\033[33m$time\033[0m\033[0m: $commit_message"
                done <<< "$commits"
            fi
            if [ "$found_commits" = false ]; then
                echo -e "\033[31m*No changes*\033[0m"
            fi
        fi
    done
    cd "$original_pwd"
}
jjjjLIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
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
    dir_part="${white_fg}${yellow_bg}\$(get_dir_part)${green_bg}${yellow_fg}"  # Yellow arrow with green background
    dir_ending_part="${white_fg}${yellow_bg}\$(get_dir_part)${black_bg}${yellow_fg}"
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
command_not_found_handle() {
    cmd="$1"
    
    if [[ $cmd != _* ]]; then
        if [[ -f "./$cmd.sh" ]]; then # Run the script
            print_info "Running script $cmd.sh"
            bash "./$cmd.sh" "${@:2}"
            return
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.sh" ]]; then
            print_info "Running script $cmd.sh"
            bash "./_lsr_scripts/$cmd.sh" "${@:2}"
            return
        elif [[ -d "./scripts" && -f "./scripts/$cmd.sh" ]]; then
            print_info "Running script $cmd.sh"
            bash "./scripts/$cmd.sh" "${@:2}"
            return
        elif [[ -f "./$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./$cmd.py" "${@:2}"
            return
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./_lsr_scripts/$cmd.py" "${@:2}"
            return
        elif [[ -d "./scripts" && -f "./scripts/$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./scripts/$cmd.py" "${@:2}"
            return
        elif [[ -f "./$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./$cmd.js" "${@:2}"
            return
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./_lsr_scripts/$cmd.js" "${@:2}"
            return
        elif [[ -d "./scripts" && -f "./scripts/$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./scripts/$cmd.js" "${@:2}"
            return
        elif [[ -f "./package.json" && "$(grep \"$cmd\": package.json)" != "" ]]; then
            print_info "Running NPM script '$cmd'"
            npm run $cmd --silent
            return
        fi
    fi
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
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".debug = $1" "$SETTINGS_FILE"
            print_info "Debug mode set to $1."
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
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
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".silent = $1" "$SETTINGS_FILE"
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
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
    mkdir -p "$local_settings_dir"
    if [[ ! -f "$local_settings_file" ]]; then
        touch "$local_settings_file"
    fi
    get_weather_settings() {
        api_key=$(yq e '.weatherapi.api_key // ""' "$local_settings_file")
        lat=$(yq e '.weatherapi.lat // ""' "$local_settings_file")
        lon=$(yq e '.weatherapi.lon // ""' "$local_settings_file")
        
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
        api_key=$(echo "$api_key" | xargs)
        lat=$(echo "$lat" | xargs)
        lon=$(echo "$lon" | xargs)
    }
    local current_time=$(date +"%H:%M %d/%m/%Y")
    get_weather_settings
    if [[ "$unconfigured" == "true" ]]; then
        print_error "Weather API is not configured in settings_data. Configure it with https://openweathermap.org/api\n"
        return 1
    fi
    
    local weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$api_key&units=metric")
    if [[ -z "$weather_data" ]] || [[ "$(echo "$weather_data" | jq '.cod')" != "200" ]]; then
        print_error "Unable to fetch weather data\n"
        return 1
    fi
    local temp_now=$(echo "$weather_data" | jq '.main.temp')
    local temp_min=$(echo "$weather_data" | jq '.main.temp_min')
    local temp_max=$(echo "$weather_data" | jq '.main.temp_max')
    local humidity=$(echo "$weather_data" | jq '.main.humidity')
    local wind_speed=$(echo "$weather_data" | jq '.wind.speed')
    local weather_condition=$(echo "$weather_data" | jq -r '.weather[0].description')
    local city=$(echo "$weather_data" | jq -r '.name')
    local bold="\033[1m"
    local green="\033[32m"
    local blue="\033[34m"
    local cyan="\033[36m"
    local reset="\033[0m"
    local red="\033[0;31m"
    local yellow='\033[0;33m'
    color_value() {
        local value="$1"
        local low_threshold="$2"
        local mid_threshold="$3"
        local high_threshold="$4"
        local colored_str
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
setup_tmux_config
tmux source-file ~/.tmux.conf
if [ -z "$TMUX" ]; then
    tmux
fi
alias tu="time_until"
alias tul="time_until_live"
time_until() {
    target0="8:30:00"
    target1="12:30:00"
    target2="17:00:00"
    
    local now=$(date +%s)
    
    today=$(date +%Y-%m-%d)
    target0_sec=$(date -d "$today $target0" +%s)
    target1_sec=$(date -d "$today $target1" +%s)
    target2_sec=$(date -d "$today $target2" +%s)
    passed0=$((now - target0_sec)) # TODO: base this on the first terminal login of the day
    remaining1=$((target1_sec - now))
    remaining2=$((target2_sec - now))
    format_time() {
        local seconds=$1
        printf "%02d:%02d:%02d\n" $((seconds/3600)) $(( (seconds%3600)/60 )) $((seconds%60))
    }
    if [ $passed0 -gt 0 ]; then
        echo "Time passed at work: $(format_time $passed0)"
    else
        echo "Work has not started yet"
    fi
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
    target1="12:30:00"
    target2="17:00:00"
    
    today=$(date +%Y-%m-%d)
    target1_sec=$(date -d "$today $target1" +%s)
    target2_sec=$(date -d "$today $target2" +%s)
    
    format_time() {
        local seconds=$1
        printf "%02d:%02d:%02d" $((seconds / 3600)) $(((seconds % 3600) / 60)) $((seconds % 60))
    }
    while true; do
        now=$(date +%s)
        
        remaining1=$((target1_sec - now))
        remaining2=$((target2_sec - now))
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
        printf "\rTime left until Break: %s | Time left until End of Day: %s" "$time_left_1230" "$time_left_1700"
        
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
        for item in *; do
            if [ -d "$item" ]; then
                lsrlist append dir_items "/$item/"
            fi
        done
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
    if [ "$pathToCopy" = "." ]; then
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
    cp -r "$HOME/.copy"/* "$target"
    cp -r "$HOME/.copy"/.* "$target" 2>/dev/null
}
alias lg="lazygit"
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
is_banned() {
  local file="$1"
  for pattern in "${banned_patterns[@]}"; do
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
    escaped_query=$(echo "$query" | sed 's/[.*+?[^$()|{}]/\\&/g')
    find . -type f | while read -r filepath; do
        if ! is_banned "$filepath"; then
            local filename=$(basename "$filepath")
            
            awk -v pattern="$escaped_query" -v fname="$filepath" '
                {
                    gsub(/^[ \t]+/, "");
                    if ($0 ~ pattern) {
                        printf "\033[0;31m%s:%d:%d\033[0m: %s\n", fname, NR, index($0, pattern), $0
                    }
                }
            ' "$filepath"
        fi
    done
}
source "$HOME/scripts/helpers.sh"
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
            
            get_length() {
                echo "${#1}"
            }
            max_content_length=$(get_length "$module_index_line")
            for line in "$module_name_line" "$line_count_line" "$filesize_line"; do
                line_length=$(get_length "$line")
                if [[ $line_length -gt $max_content_length ]]; then
                    max_content_length=$line_length
                fi
            done
            max_line_length=$((max_content_length + 2)) # +2 for the hashtags on each side
            horizontal_line=$(printf "#%0.s" $(seq 1 $max_line_length))
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
    print_empty_line
    print_info "Generating minimized build file"
    local remove_comment_lines='^\s*#'  # Matches lines that are just comments
    local trim_whitespace='^\s*|\s*$'   # Matches leading and trailing whitespace on each line
    local remove_empty_lines='^$'       # Matches empty lines
    
    if [[ ! -f $minimized_build_file ]]; then
        touch "$minimized_build_file"
    fi
    cp "$build_file" "$minimized_build_file"
    sed -i "/$remove_comment_lines/d" "$minimized_build_file"
    sed -i "s/$trim_whitespace//g" "$minimized_build_file"
    sed -i "/$remove_empty_lines/d" "$minimized_build_file"
    print_info "Total final build.min.sh size: $(get_filesize "$minimized_build_file")"
    print_info "Total final build.min.sh lines: $(get_line_count "$minimized_build_file")"
    reload_bash
}
start_remote_log_catcher_server() {
    PORT="$1"
    URL="$2"
    if [[ -z $1 ]]; then
        PORT=43872
    fi
    echo "Server running on port $URL, waiting for requests..."
    while true; do
        request=$(nc -l -p "$PORT" -w 1)  # -w 5 means wait for up to 5 seconds for data
        if [ -z "$request" ]; then
            continue
        fi
        body=$(echo "$request" | sed -n '/^\r$/,$p' | tail -n +2)
        print_info "$request"
    done
}
locallog() {
    port="$1"
    if [[ -z $1 ]]; then
        port=58473
    fi
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
    pgrep ngrok > /dev/null
    if [ $? -eq 0 ]; then
        print_info "ngrok was already running, killing other instance... you can only have one ngrok/remotelog instance running."
        pkill ngrok  # Kill any running ngrok processes
        sleep 1  # Give a moment for the processes to terminate
    fi
    port="$1"
    if [[ -z $1 ]]; then
        port=58473
    fi
    print_info "Initializing server..."
    ngrok http $port --log $LOG_FILE &
    NGROK_PID=$!
    while ! grep -q 'https://[a-z0-9\-]*.ngrok-free.app' $LOG_FILE; do
        sleep 1  # Wait until the URL is available in the log
    done
    NGROK_URL=$(grep 'https://[a-z0-9\-]*.ngrok-free.app' $LOG_FILE | awk -F"url=" '{print $2}' | awk '{print $1}')
    echo "Your ngrok URL is: $NGROK_URL"
    start_remote_log_catcher_server $port $NGROK_URL
}
lsrlist() {
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
LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
alias dock="dock_main_command"
dock_main_command() {
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
    
    declare -A projects
    declare -A project_status
    while IFS= read -r container; do
        container_id=$(echo "$container" | awk '{print $1}')
        container_name=$(echo "$container" | awk '{print $2}')
        project_name=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' "$container_id")
        status=$(docker inspect --format '{{.State.Status}}' "$container_id")
        if [[ -n "$project_name" ]]; then
            projects["$project_name"]+="$container_id:$container_name;"
            if [[ -z "${project_status[$project_name]}" ]]; then
                project_status["$project_name"]="$status"
            fi
        fi
    done < <(docker ps -aq)  # Read all container IDs
    longest_name=0
    for project in "${!projects[@]}"; do
        length=${#project}
        if (( length > longest_name )); then
            longest_name=$length
        fi
    done
    printf "${YELLOW}%-5s\t%-${longest_name}s\t%s\n${RESET}" "Index" "Project Name" "Status"  # Fixed-width headers
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
    mapfile -t project_names < <(docker ps -aq --filter "label=com.docker.compose.project" | xargs docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u)
    project_name="${project_names[$(( $1 - 1 ))]}"  # Convert to zero-based index
    if [ -z "$project_name" ]; then
        print_error "No project found at index $1."
        return 1
    fi
    container_ids=$(docker ps -aq --filter "label=com.docker.compose.project=$project_name")
    if [ -z "$container_ids" ]; then
        print_error "No stopped containers found for project '$project_name'."
        return 1
    fi
    print_success "Starting containers for project: $project_name"
    docker start $container_ids
}
dock_stop_project() {
    if [ -z "$1" ]; then
        print_error "Usage: dockstop <number>"
        return 1
    fi
    project_name=$(docker ps --format '{{.ID}}' | xargs docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u | sed -n "1p")
    print_debug $project_name
    if [ -z "$project_name" ]; then
        print_error "No project found at index $1."
        return 1
    fi
    container_ids=$(docker ps -q --filter "label=com.docker.compose.project=$project_name")
    if [ -z "$container_ids" ]; then
        print_error "No running containers found for project '$project_name'."
        return 1
    fi
    print_success "Stopping containers for project: $project_name"
    docker stop $container_ids
}
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
    if docker info >/dev/null 2>&1; then
        print_success "Docker is now running."
    else
        print_error "Failed to start Docker."
    fi
}
alias gitusers="git_users_main_command"
git_users_main_command() {
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
    local identifier=$(prompt_if_not_exists "Identifier" $1)
    
    localsettings_reformat
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi
    localsettings_eval ".gitusers.\"$identifier\""
}
git_users_new() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)
    local getResult=$(localsettings_eval ".gitusers.\\\"$identifier\\\"")
    if [[ ! "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier already exists"
        return 1
    fi
    local fullname=$(prompt_if_not_exists "Fullname" $2)
    localsettings_eval_with_save ".gitusers.\"$identifier\".fullname = \"$fullname\"" > /dev/null
    localsettings_eval_with_save ".gitusers.\"$identifier\".aliases = [ \"$fullname\" ]" > /dev/null
    localsettings_reformat
    print_success "Created gituser \"$identifier\""
}
git_users_delete() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)
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
alias branches="git_branches_main_command"
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
local_settings_file="$HOME/scripts/local_data/local_settings.yml"
local_settings_dir="$(dirname "$local_settings_file")"
alias profile="profile_main_command"
profile_main_command() {
    reset_ifs
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
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile delete <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1
    if [[ "$current_profile" == "$profile" ]]; then
        print_error "Cant delete current profile"
        return 1
    fi
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
    if [ "$#" -ne 1 ]; then
        profile_select
        return 0  # Return an error code
    fi
    local profile=$1
    if [[ ! -f "$local_settings_dir/local_settings.$profile.yml" ]]; then
        print_error "Profile '$profile' doesnt exist"
    fi
    cp "$local_settings_dir/local_settings.$profile.yml" "$local_settings_dir/local_settings.yml"
    print_success "Loaded profile local_settings.$profile.yml"
}
profile_save() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile save <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1
    local current_profile="$(profile_current)"
    lsset profile $profile &> /dev/null
    if [[ -f "$local_settings_dir/local_settings.$profile.yml" && $profile != $current_profile ]]; then
        print_error "Aborting since this will overwrite existing profile '$profile'"
        return 1
    fi
    cp "$local_settings_dir/local_settings.yml" "$local_settings_dir/local_settings.$profile.yml"
    print_success "Saved current profile to local_settings.$profile.yml"
}
profile_edit() {
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
