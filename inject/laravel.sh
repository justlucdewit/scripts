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

start() {
    create_start_layout

    run_in_pane 0 "clear"
    run_in_pane 1 "clear"
    run_in_pane 2 "clear"
    
    run_in_pane 2 el 30
    run_in_pane 2 clear
    run_in_pane 2 tls
    run_in_pane 2 code .

    # Get the first available npm script
    npm_script=$(get_first_npm_script)

    # Start the compilers
    print_info "starting npm with 'npm run $npm_script'"
    run_in_pane 1 "npm run $npm_script"
    print_info "starting sail..."
    run_in_pane 0 sail up
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