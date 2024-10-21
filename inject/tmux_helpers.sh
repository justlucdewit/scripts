alias shor="tmux split-window -h"
alias sver="tmux split-window -v"
alias ml="tmux select-pane -L"
alias mr="tmux select-pane -R"
alias md="tmux select-pane -D"
alias mu="tmux select-pane -U"
alias close="tmux kill-pane"

set_window_name() {
    local new_name="$1"

    # Ensure the window is unique and not a race condition
    tmux rename-window "$new_name"
}

run_command_in_pane() {
    local pane_name="$1"
    local command="$2"

    # Check if the pane exists (using the current window)
    local current_window=$(tmux display-message -p '#W')

    # Create a new pane if it does not exist
    if ! tmux list-panes -t "$current_window" | grep -q "$pane_name"; then
        tmux split-window -h  # Split horizontally to create a new pane
        set_pane_name "$pane_name"  # Set the name for the new pane
    fi

    # Send the command to the specified pane
    tmux send-keys -t "$current_window:$pane_name" "$command" C-m  # C-m simulates pressing Enter
}

set_pane_name() {
    local new_name="$1"

    # Get the current pane ID
    local current_pane_id=$(tmux display-message -p '#P')

    # Rename the current pane using the pane ID
    tmux select-pane -t "$current_pane_id"
    tmux select-pane -T "$new_name"  # This sets the pane title
}

restore() {
    # Get the current pane ID (the one where the command was executed)
    local current_pane_id=$(tmux display-message -p '#P')

    # Get the list of all pane IDs, including their names for debugging
    local pane_ids=$(tmux list-panes -F '#P')

    for pane_id in $pane_ids; do
        if [[ "$pane_id" != "$current_pane_id" ]]; then
            echo "Sending stop signal to pane $pane_id"
            # Send the "SIGINT" signal (Ctrl+C) to the process running in the pane
            tmux send-keys -t "$pane_id" C-c  # Sends Ctrl+C to the pane
            tmux send-keys -t "$pane_id" "clear" C-m  # Sends Ctrl+C to the pane
            sleep 1  # Wait for the process to handle the signal
        fi
    done

    # Loop through the panes and kill each one that isn't the current pane
    for pane_id in $pane_ids; do
        if [[ "$pane_id" != "$current_pane_id" ]]; then
            # Attempt to close the pane
            if tmux kill-pane -t "$pane_id"; then
                echo "Closed pane $pane_id"
            else
                echo "Failed to close pane $pane_id"
            fi
        fi
    done
}


fresh() {
    sudo -rf node_modules
    sudo -rf vendor
    npm i
    composer i
}

init_session_name() {
    # Get the current session name
    local session_name=$(tmux display-message -p '#S')

    # Check if the session name is empty or just a number (unnamed)
    if [[ -z "$session_name" || "$session_name" =~ ^[0-9]+$ ]]; then
        # Generate a random name
        local random_name="session_$(date +%s%N | sha256sum | base64 | head -c 8)"
        
        # Rename the current session
        tmux rename-session "$random_name"
        echo "Initialized session name to: $random_name"
    else
        echo "Current session name: $session_name"
    fi
}

list_panes() {
    # Get the current window ID
    local current_window=$(tmux display-message -p '#W')

    # List all panes in the current window with their IDs and titles
    echo "Panes in window '$current_window':"
    tmux list-panes -t "$current_window" -F "#{pane_id}: (#{pane_title})" | nl
}

start() {
    init_session_name
    declare -A npm_start_commands=(
        ["website-spectrum-59-q3-2022"]="dev"
    );

    declare -A sdfsdfsdf=(
    );

    local curr_dir=$(basename $(pwd))
    local current_window_index=$(tmux display-message -p '#I')
    local current_session=$(tmux display-message -p '#S')
    
    if [[ -v npm_start_commands["$curr_dir"] ]]; then
        local curr_npm_start_command="${npm_start_commands[$curr_dir]}"

        local npm_pane="Npm-$curr_dir"
        local sail_pane="Sail-$curr_dir"
        local terminal_pane="Terminal-$curr_dir"
        

        set_pane_name $sail_pane
        local sail_pane_index=$(tmux display-message -p '#P')
        shor
        set_pane_name $terminal_pane
        local terminal_pane_index=$(tmux display-message -p '#P')
        ml
        sver
        set_pane_name $npm_pane
        local npm_pane_index=$(tmux display-message -p '#P')
        mr

        tmux send-keys -t $current_session:$current_window.$npm_pane_index "npm run $curr_npm_start_command" C-m
        tmux send-keys -t $current_session:$current_window.$sail_pane_index "sail up" C-m
        tmux send-keys -t $current_session:$current_window.$terminal_pane_index "code ." C-m
        sleep 3
        tmux send-keys -t $current_session:$current_window.$terminal_pane_index "clear" C-m
    else
        echo "Project is not configured yet"
    fi
}