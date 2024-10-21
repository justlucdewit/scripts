# TODO: Fix bug where using 2 sessions in paralel destroys tmux_pane_names.txt in localdata
# TODO: Fix bug where sometimes pane names are forgotten

INDENT="    "
INACTIVE_LIST_ITEM=" - "
ACTIVE_LIST_ITEM=" * "
PANE_NAME_FILE="$HOME/scripts/local_data/tmp/tmux_pane_names.txt"

# Load pane names from the file into the associative array
declare -gA pane_names

set_stored_pane_name() {
    local key="$1"
    local value="$2"
    pane_names["$key"]="$value"
}

sync_pane_names() {
    
    # Make a copy of the old pane names
    declare -A old_pane_names 
    for key in "${!pane_names[@]}"; do
        old_pane_names["$key"]="${pane_names[$key]}"
    done

    # Clear the pane names array and set it to the save file
    unset pane_names
    declare -gA pane_names
    load_pane_names

    # Loop over the pane names from the save file, and remove it if it does not exist in the old_pane_names
    for key in "${!pane_names[@]}"; do
        if [[ -z "${old_pane_names[$key]}" ]]; then
            unset 'pane_names[$key]'  # Remove the key if it doesn't exist in old_pane_names
        fi
    done

    # Try to find new, unregistered panes that are not named yet across all sessions
    sessions=$(tmux list-sessions -F '#S')  # Get all session names

    for session in $sessions; do
        current_windows=$(tmux list-windows -t "$session" -F '#I')  # Get window indices for each session

        for window in $current_windows; do
            # List all panes in the current window
            panes=$(tmux list-panes -t "$session:$window" -F '#P')

            for pane in $panes; do
                # Create a key for the current pane
                pane_key="$session:$window:$pane"

                # Check if this pane is not already in pane_names
                if [[ -z "pane_names[$pane_key]" ]]; then
                    # If it's a new pane, assign it a default name
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
alias sr=""
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
    current_pane=$(tmux display -p '#P')

    # Create a unique key for the pane
    pane_key="${current_session}:${current_window}:${current_pane}"
    echo "test - $pane_key"

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

    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')
    current_pane_number=$(tmux display -p '#P')

    # Create a unique key for the current pane
    pane_key="${current_session}:${current_window}:${current_pane_number}"
    current_pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}

    echo -e "${ACTIVE_LIST_ITEM}Session $current_session: \e[1;34m$current_session\e[0m"
    echo -e "${INDENT}${ACTIVE_LIST_ITEM}\e[1;32mWindow $current_window: ${window_name}\e[0m"
    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $current_pane_number: $current_pane_name\e[0m"
}

tlist() {
    load_pane_names
    sync_pane_names

    # List all tmux sessions
    tmux list-sessions -F '#S' | nl -w1 -s': ' | while read session; do
        session_number=$(echo "$session" | cut -d':' -f1 | xargs)  # Get the session number
        session_name=$(echo "$session" | cut -d':' -f2 | xargs)    # Get the session name

        # Output session name with color
        echo -e "${INACTIVE_LIST_ITEM}\e[1;34mSession $session_number: $session_name\e[0m"

        # List windows in the current session
        tmux list-windows -t "$session_name" -F '#I: #W' | while read -r window; do
            # Extract window number and name
            window_number=$(echo "$window" | cut -d':' -f1 | xargs)  # Get the window number
            window_name=$(echo "$window" | cut -d':' -f2 | xargs)    # Get the window name

            # Output window number and name with color
            echo -e "${INDENT}${INACTIVE_LIST_ITEM}\e[1;32mWindow $window_number: $window_name\e[0m"

            tmux list-panes -t "$session_name:$window_number" -F '#P: #T' | while read -r pane; do
                pane_number=$(echo "$pane" | cut -d':' -f1 | xargs)  # Get the pane number

                # Create a unique key for the pane
                pane_key="${session_name}:${window_number}:${pane_number}"
                pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}

                # Output pane number and name with color
                echo -e "${INDENT}${INDENT}${INACTIVE_LIST_ITEM}\e[1;33mPane $pane_number: $pane_name\e[0m"
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
    local current_pane=$(tmux display-message -p '#P')
    
    # Get the target pane number and remove it from
    # the commandline argument list
    local target_pane=$1
    shift
    
    # Run the command in the target pane
    local command="$*"
    tmux send-keys -t $target_pane "$command" C-m
}

# Print the current pane number
alias tcur="tmux display-message -p 'Current pane number: #P'"

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

# load_pane_names

# set_window_name() {
#     local new_name="$1"

#     # Ensure the window is unique and not a race condition
#     tmux rename-window "$new_name"
# }

# run_command_in_pane() {
#     local pane_name="$1"
#     local command="$2"

#     # Check if the pane exists (using the current window)
#     local current_window=$(tmux display-message -p '#W')

#     # Create a new pane if it does not exist
#     if ! tmux list-panes -t "$current_window" | grep -q "$pane_name"; then
#         tmux split-window -h  # Split horizontally to create a new pane
#         set_pane_name "$pane_name"  # Set the name for the new pane
#     fi

#     # Send the command to the specified pane
#     tmux send-keys -t "$current_window:$pane_name" "$command" C-m  # C-m simulates pressing Enter
# }

# set_pane_name() {
#     local new_name="$1"

#     # Get the current pane ID
#     local current_pane_id=$(tmux display-message -p '#P')

#     # Rename the current pane using the pane ID
#     tmux select-pane -t "$current_pane_id"
#     tmux select-pane -T "$new_name"  # This sets the pane title
# }

# restore() {
#     # Get the current pane ID (the one where the command was executed)
#     local current_pane_id=$(tmux display-message -p '#P')

#     # Get the list of all pane IDs, including their names for debugging
#     local pane_ids=$(tmux list-panes -F '#P')

#     for pane_id in $pane_ids; do
#         if [[ "$pane_id" != "$current_pane_id" ]]; then
#             echo "Sending stop signal to pane $pane_id"
#             # Send the "SIGINT" signal (Ctrl+C) to the process running in the pane
#             tmux send-keys -t "$pane_id" C-c  # Sends Ctrl+C to the pane
#             tmux send-keys -t "$pane_id" "clear" C-m  # Sends Ctrl+C to the pane
#             sleep 1  # Wait for the process to handle the signal
#         fi
#     done

#     # Loop through the panes and kill each one that isn't the current pane
#     for pane_id in $pane_ids; do
#         if [[ "$pane_id" != "$current_pane_id" ]]; then
#             # Attempt to close the pane
#             if tmux kill-pane -t "$pane_id"; then
#                 echo "Closed pane $pane_id"
#             else
#                 echo "Failed to close pane $pane_id"
#             fi
#         fi
#     done
# }


# fresh() {
#     sudo -rf node_modules
#     sudo -rf vendor
#     npm i
#     composer i
# }

# init_session_name() {
#     # Get the current session name
#     local session_name=$(tmux display-message -p '#S')

#     # Check if the session name is empty or just a number (unnamed)
#     if [[ -z "$session_name" || "$session_name" =~ ^[0-9]+$ ]]; then
#         # Generate a random name
#         local random_name="session_$(date +%s%N | sha256sum | base64 | head -c 8)"
        
#         # Rename the current session
#         tmux rename-session "$random_name"
#         echo "Initialized session name to: $random_name"
#     else
#         echo "Current session name: $session_name"
#     fi
# }

# list_panes() {
#     # Get the current window ID
#     local current_window=$(tmux display-message -p '#W')

#     # List all panes in the current window with their IDs and titles
#     echo "Panes in window '$current_window':"
#     tmux list-panes -t "$current_window" -F "#{pane_id}: (#{pane_title})" | nl
# }

# start() {
#     init_session_name
#     declare -A npm_start_commands=(
#         ["website-spectrum-59-q3-2022"]="dev"
#     );

#     declare -A sdfsdfsdf=(
#     );

#     local curr_dir=$(basename $(pwd))
#     local current_window_index=$(tmux display-message -p '#I')
#     local current_session=$(tmux display-message -p '#S')
    
#     if [[ -v npm_start_commands["$curr_dir"] ]]; then
#         local curr_npm_start_command="${npm_start_commands[$curr_dir]}"

#         local npm_pane="Npm-$curr_dir"
#         local sail_pane="Sail-$curr_dir"
#         local terminal_pane="Terminal-$curr_dir"
        

#         set_pane_name $sail_pane
#         local sail_pane_index=$(tmux display-message -p '#P')
#         shor
#         set_pane_name $terminal_pane
#         local terminal_pane_index=$(tmux display-message -p '#P')
#         ml
#         sver
#         set_pane_name $npm_pane
#         local npm_pane_index=$(tmux display-message -p '#P')
#         mr

#         tmux send-keys -t $current_session:$current_window.$npm_pane_index "npm run $curr_npm_start_command" C-m
#         tmux send-keys -t $current_session:$current_window.$sail_pane_index "sail up" C-m
#         tmux send-keys -t $current_session:$current_window.$terminal_pane_index "code ." C-m
#         sleep 3
#         tmux send-keys -t $current_session:$current_window.$terminal_pane_index "clear" C-m
#     else
#         echo "Project is not configured yet"
#     fi
# }