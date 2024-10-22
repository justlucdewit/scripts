# TODO: Fix bug where when pane 1 is closed, pane 2 will become 1 and thus take its name

DEBUG_CACHE_WRITING=false
INDENT="    "
INACTIVE_LIST_ITEM=" - "
ACTIVE_LIST_ITEM=" * "
PANE_NAME_FILE="$HOME/scripts/local_data/tmp/tmux_pane_names.txt"

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
alias wc="tmux kill-window" # Close window
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
    pane_name=$1
    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')
    current_pane=$(tmux display -p '#D')

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
    current_pane_id=$(tmux display -p '#D')  # Unique pane ID

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
    active_pane=$(tmux display-message -p '#D')

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
                pane_number=$(echo "$pane" | cut -d':' -f1 | xargs)  # Get the pane number

                # Create a unique key for the pane
                pane_key="${session_name}:${window_number}:${pane_number}"
                pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}

                # Check if pane is active
                if [ "$session_name" == "$active_session" ] && [ "$window_number" == "$active_window" ] && [ "$pane_number" == "$active_pane" ]; then
                    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $pane_number: $pane_name\e[0m"
                else
                    echo -e "${INDENT}${INDENT}${INACTIVE_LIST_ITEM}\e[1;33mPane $pane_number: $pane_name\e[0m"
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

# Print the current pane number
alias tcur="tmux display-message -p 'Current pane number: #D'"

# Use this to start tmux:
#   - Creates new session if none found
#   - if session found, use that one
t() {
    sync_pane_names
    tmux has-session -t "dev" 2>/dev/null
    if [ $? != 0 ]; then
        echo "Creating new session: dev"
        tmux new -s "dev"
    else
        echo "Attaching to existing session: dev"
        tmux attach-session -t "dev"
    fi
}

alias tclose="tmux kill-pane"
tcloseall() {
    tmux kill-pane -a
    echo "All panes in the current window killed."
    tclose # Close the last pane
}

alias tca="tcloseall"
alias rip="run_in_pane"
alias tc="tclose"
