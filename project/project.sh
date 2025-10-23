source "$HOME/.lsr_core/core/lsr.core.sh"

# [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"

PROJECT_FILE="$HOME/projects/projects.json"
PROJECT_DIR="$HOME/projects/"

LSR_COMMAND_SET_HELP "project.current" "Show the name of the current project if any"
project_current() {
    local dir="$(echo "$PWD")"

    # Check if the directory starts with the project root
    if [[ "$dir" == "$PROJECT_DIR"* ]]; then
        # Remove the project root part from the directory string
        # using parameter expansion
        dir="${dir#$PROJECT_DIR}"
    fi

    local project_config="$(jq --arg current_dir "$dir" '.[] | select(.dir == $current_dir)' "$PROJECT_FILE")"
    
    echo "$project_config" | jq -r ".code"
}

LSR_COMMAND_SET_HELP "project.json" "Show the JSON config of the current project if any"
project_json() {
    local dir="$(echo "$PWD")"

    # Check if the directory starts with the project root
    if [[ "$dir" == "$PROJECT_DIR"* ]]; then
        # Remove the project root part from the directory string
        # using parameter expansion
        dir="${dir#$PROJECT_DIR}"
    fi
    
    local project_config="$(jq --arg current_dir "$dir" '.[] | select(.dir == $current_dir)' "$PROJECT_FILE")"
    
    echo "$project_config" | jq -r "."
}

LSR_COMMAND_SET_HELP "project.list" "List all available projects"
project_list() {
    echo "$(jq -r ".[] | \" - \" + .code" "$PROJECT_FILE")"
}

LSR_COMMAND_SET_HELP "project.go" "Go to the directory of a specific project"
project_go() {
    local project_code="$1"

    if [[ $project_code == "" ]]; then
        project_list
        return
    fi

    local project_dir="$(jq -r --arg code "$project_code" '.[] | select(.code == $code) | .dir' "$PROJECT_FILE")"
    if [[ -z "$project_dir" || "$project_dir" == "null" ]]; then
        print_error "No project found with code '$project_code'"
        return
    fi

    cd "$HOME/projects/$project_dir"
}

LSR_COMMAND_SET_HELP "project.open-site" "Open a website of the current project"
project_open_site() {
    local site_to_open="$1"

    local dir="$(echo "$PWD")"

    # Check if the directory starts with the project root
    if [[ "$dir" == "$PROJECT_DIR"* ]]; then
        # Remove the project root part from the directory string
        # using parameter expansion
        dir="${dir#$PROJECT_DIR}"
    fi

    local project_config="$(jq --arg current_dir "$dir" '.[] | select(.dir == $current_dir)' "$PROJECT_FILE")"

    # If we are not in a project directory, return error
    if [[ -z "$project_config" ]]; then
        print_error "Not in a project directory"
        return;
    fi

    # Get needed project parameters
    local project_code="$(echo "$project_config" | jq -r ".code")"
    local project_sites="$(echo "$project_config" | jq -r ".sites")"

    # If project has no sites, return error
    if [[ -z "$project_sites" || "$project_sites" == "null" || "$project_sites" == "{}" ]]; then
        print_error "Project '$project_code' has no sites defined in config"
        return;
    fi

    # Open the site given by the user
    local url_to_open=""
    if [[ -n "$site_to_open" ]]; then
        url_to_open="$(echo "$project_sites" | jq -r --arg site "$site_to_open" '.[$site]')"

    # Show list of available sites and let user pick one
    else
        echo "$project_sites" | jq -r 'to_entries[] | " - " + .key'
        echo -n "What site to open: "
        read -r site
        url_to_open="$(echo "$project_sites" | jq -r --arg site "$site" '.[$site]')"
    fi
    
    # Open the URL in the default browser
    if [[ -n "$url_to_open" && "$url_to_open" != "null" ]]; then
        echo "Opening $url_to_open..."
        open "$url_to_open"
    else
        print_error "No site found with key '$site'"
    fi
}

LSR_COMMAND_SET_HELP "project.open-ssh" "Open a ssh connection to one of the project's servers"
project_open_ssh() {
    local connection_to_open="$1"

    local dir="$(echo "$PWD")"

    # Check if the directory starts with the project root
    if [[ "$dir" == "$PROJECT_DIR"* ]]; then
        # Remove the project root part from the directory string
        # using parameter expansion
        dir="${dir#$PROJECT_DIR}"
    fi

    local project_config="$(jq --arg current_dir "$dir" '.[] | select(.dir == $current_dir)' "$PROJECT_FILE")"

    # If we are not in a project directory, return error
    if [[ -z "$project_config" ]]; then
        print_error "Not in a project directory"
        return;
    fi

    # Get needed project parameters
    local project_code="$(echo "$project_config" | jq -r ".code")"
    local project_ssh_connections="$(echo "$project_config" | jq -r ".ssh_connections")"

    if [[ -z "$project_ssh_connections" || "$project_ssh_connections" == "null" || "$project_ssh_connections" == "{}" ]]; then
        print_error "Project '$project_code' has no ssh connections defined in config"
        return;
    fi

    # Open the connection given by the user
    local ssh_connection=""
    local ssh_folder=""
    if [[ -n "$connection_to_open" ]]; then
        ssh_connection="$(echo "$project_ssh_connections" | jq -r --arg conn "$connection_to_open" '.[ $conn ][0]')"
        ssh_folder="$(echo "$project_ssh_connections" | jq -r --arg conn "$connection_to_open" '.[ $conn ][1]')"

    # Show list of available connections and let user pick one
    else
        echo "$project_ssh_connections" | jq -r 'to_entries[] | " - " + .key'
        echo -n "What connection to open: "
        read -r connection
        ssh_connection="$(echo "$project_ssh_connections" | jq -r --arg conn "$connection" '.[ $conn ][0]')"
        ssh_folder="$(echo "$project_ssh_connections" | jq -r --arg conn "$connection" '.[ $conn ][1]')"
        # url_to_open="$(echo "$project_sites" | jq -r --arg site "$site" '.[$site]')"
    fi

    ssh -t "$ssh_connection" "cd $ssh_folder ; bash --login"
}

LSR_COMMAND_SET_HELP "project.open-forge" "Open one of the forge pages belonging to this project"
project_open_forge() {
    local forge_site_to_open="$1"
    local forge_section="$2"

    local dir="$(echo "$PWD")"

    # Check if the directory starts with the project root
    if [[ "$dir" == "$PROJECT_DIR"* ]]; then
        # Remove the project root part from the directory string
        # using parameter expansion
        dir="${dir#$PROJECT_DIR}"
    fi

    local project_config="$(jq --arg current_dir "$dir" '.[] | select(.dir == $current_dir)' "$PROJECT_FILE")"

    # If we are not in a project directory, return error
    if [[ -z "$project_config" ]]; then
        print_error "Not in a project directory"
        return;
    fi

    # Get needed project parameters
    local project_code="$(echo "$project_config" | jq -r ".code")"
    local project_forge_sites="$(echo "$project_config" | jq -r ".forge_sites")"

    if [[ -z "$project_forge_sites" || "$project_forge_sites" == "null" || "$project_forge_sites" == "{}" ]]; then
        print_error "Project '$project_code' has no forge sites defined in config"
        return;
    fi

    # Open the connection given by the user
    local forge_base_url=""
    if [[ -n "$forge_site_to_open" ]]; then
        forge_base_url="$(echo "$project_forge_sites" | jq -r --arg site "$forge_site_to_open" '.[$site]')"

    # Show list of available forge sites and let user pick one
    else
        echo "$project_forge_sites" | jq -r 'to_entries[] | " - " + .key'
        echo -n "What forge site to open: "
        read -r site
        forge_base_url="$(echo "$project_forge_sites" | jq -r --arg site "$site" '.[$site]')"
    fi

    local url_postfix=""
    if [[ -z "$forge_section" ]]; then
        url_postfix=""
    elif [[ "$forge_section" == "settings" ]]; then
        url_postfix="/settings"
    elif [[ "$forge_section" == "env" ]]; then
        url_postfix="/environment"
    elif [[ "$forge_section" == "deployment" ]]; then
        url_postfix="/deployments"
    elif [[ "$forge_section" == "logs" ]]; then
        url_postfix="/observe/logs"
    elif [[ "$forge_section" == "overview" ]]; then
        url_postfix=""
    else
        print_error "Unknown forge section '$forge_section'"
        print_error "Available sections: overview, settings, env, deployment, logs"
        return
    fi

    echo "Opening $forge_base_url$url_postfix..."
    open "$forge_base_url$url_postfix"
}

# LSR_COMMAND "project" "$@"

# LSR_SET_SUBCOMMAND "go" "<projectname>"
# LSR_SET_SUBCOMMAND "install" "<projectname>"
# LSR_SET_SUBCOMMAND "uninstall" "<projectname>"
# LSR_SET_SUBCOMMAND "start" "<projectname>"
# LSR_SET_SUBCOMMAND "build" "<projectname>"

# LSR_SET_SUBCOMMAND "info" "<projectname>"

# LSR_DESCRIBE_SUBCOMMAND "list" "List all of the registered projects and demos"
# LSR_DESCRIBE_SUBCOMMAND "go" "Go to the directory of the project"
# LSR_DESCRIBE_SUBCOMMAND "install" "Install the project locally"
# LSR_DESCRIBE_SUBCOMMAND "uninstall" "Install the project locally"
# LSR_DESCRIBE_SUBCOMMAND "start" "Starts the project in the current terminal"
# LSR_DESCRIBE_SUBCOMMAND "build" "Makes a build of the project"
# LSR_DESCRIBE_SUBCOMMAND "current" "Shows the current project code"
# LSR_DESCRIBE_SUBCOMMAND "links" "List all websites or resources belonging to this project"
# LSR_DESCRIBE_SUBCOMMAND "info" "Show info about project"

# LSR_CLI_INPUT_PARSER $@

# DEFAULT_CONFIG_TO_CURRENT="true"

# project_repo_to_name() {
#     local repo="$1"

#     # Make sure git repository is cloned
#     if [[ "$repo" == "codecommit::"* ]]; then
#         # Codecommit repository
#         repo=$(echo "$repo" | sed -E 's|.*//([^/]+)|\1|')
#     fi

#     echo "$repo"
# }

# project_query_to_code() {
#     local query="$1"

#     if str_empty "$query" && str_equals "$DEFAULT_CONFIG_TO_CURRENT" "true"; then
#         query="$(project_current)"
#     fi

#     local project_code1="$(jq -r ".[] | select(.code == \"$query\") | .code" "$HOME/projects/projects.json")"
#     local project_code2="$(jq -r ".[] | select(.code == \"website-$query\") | .code" "$HOME/projects/projects.json")"
#     local project_code3="$(jq -r ".[] | select(.code == \"demo-$query\") | .code" "$HOME/projects/projects.json")"
#     local project_code4="$(jq -r ".[] | select(.code == \"demo-\" + .client + \"-$query\") | .code" "$HOME/projects/projects.json")"
#     local project_code5="$(jq -r ".[] | select(.code == \"website-\" + .client + \"-$query\") | .code" "$HOME/projects/projects.json")"

#     if ! str_empty "$project_code1"; then
#         echo "$project_code1"
#         return
#     fi

#     if ! str_empty "$project_code2"; then
#         echo "$project_code2"
#         return
#     fi

#     if ! str_empty "$project_code3"; then
#         echo "$project_code3"
#         return
#     fi

#     if ! str_empty "$project_code4"; then
#         echo "$project_code4"
#         return
#     fi

#     if ! str_empty "$project_code5"; then
#         echo "$project_code5"
#         return
#     fi
# }

# project_helper_find_config() {
#     local query="$1"
#     local project_code="$(project_query_to_code "$query")"

#     if str_empty "$query" && str_equals "$DEFAULT_CONFIG_TO_CURRENT" "true"; then
#         query="$(project_current)"
#     fi

#     local project_json="$(jq -r ".[] | select(.code == \"$project_code\")" "$HOME/projects/projects.json")"
#     echo "$project_json"
# }

# project_code_to_query() {
#     local code="$1"
#     local code="$(project_query_to_code "$code")"
#     local json="$(project_helper_find_config "$code")"
#     local client="$(echo "$json" | jq -r ".client")"

#     code="$(echo "$code" | sed -E 's/^(website-|demo-)//')"
#     if [[ "$client" != "null" ]]; then
#         code="$(echo "$code" | sed -E "s/^($client-)//")"
#     fi

#     echo "$code"
# }

# project_info() {
#     local project_json="$(project_helper_find_config "$query")"

#     local project_active="$(echo "$project_json" | jq -r ".active")"
#     local project_repo="$(echo "$project_json" | jq -r ".repo")"
#     local project_dir="$(echo "$project_json" | jq -r ".dir")"
#     local project_code="$(echo "$project_json" | jq -r ".code")"
#     local project_websites="$(echo "$project_json" | jq -r "(.sites // []) | to_entries[] | .key")"
#     local project_servers="$(echo "$project_json" | jq -r "(.forgeIds // []) | to_entries[] | .key")"

#     echo
#     echo "Project Info for '$project_code'"
#     if str_equals "$project_active" "true"; then
#         echo "  - Project is active"
#     else
#         echo "  - Project is inactive"
#     fi

#     echo "  - Repository: https://bitbucket.org/xingredient/$project_repo/src"

#     echo
#     echo "Technology used: "
#     local tech_used="$(echo "$project_json" | jq -r ".versions | to_entries[] | .key")"
#     for tech in $(echo "$tech_used" | tr '\n' ' '); do
#         local version="$(echo "$project_json" | jq -r ".versions.$tech")"
#         echo -e "  - $LSR_COLOR_GREEN$tech:$LSR_COLOR_RESET v$version"
#     done

#     echo
#     local branches_list="$(git for-each-ref --format='%(refname:short) %(authordate:short) %(authorname)' refs/heads)"
#     local normal_count=0
#     local feature_count=0
#     local text_buffer=""
#     while read -r branch date author; do
#         if [[ "$branch" == feature/* ]]; then
#             ((feature_count++))
#         else
#             ((normal_count++))
#         fi
        
#         if [[ -n text_buffer ]]; then
#             text_buffer+=$'\n'
#         fi
#         text_buffer="$text_buffer - $branch (last updated on $LSR_COLOR_GREEN$date$LSR_COLOR_RESET by $LSR_COLOR_GREEN$author$LSR_COLOR_RESET)"
#     done <<< "$branches_list"
#     echo "Branches ($normal_count normal branches; $feature_count feature branches):"
#     echo -e "$text_buffer"

#     echo
# }

# # uninstallation of node packages
# # uninstallation of composer packages
# project_uninstall() {
#     local project_entry="$(project_helper_find_config "$1")"

#     if str_empty "$project_entry"; then
#         print_error "No project found with code '$1'"
#         return
#     fi

#     local project_repo="$(echo "$project_entry" | jq -r ".dir")"

#     # Uninstall node packages
#     if [[ -d "$HOME/projects/$project_repo/node_modules" ]]; then
#         print_success "Uninstalled node packages"
#         rm -rf "$HOME/projects/$project_repo/node_modules"
#     fi

#     #Uninstall composer packages
#     if [[ -d "$HOME/projects/$project_repo/vendor" ]]; then
#         print_success "Uninstalled composer"
#         rm -rf "$HOME/projects/$project_repo/vendor"
#     fi
# }

# # installation of repository
# # installation of node version
# # installation of php version
# # installation of node packages
# # installation of composer packages
# project_install() {
#     local project_entry="$(project_helper_find_config "$1")"

#     if str_empty "$project_entry"; then
#         print_error "No project found with code '$1'"
#         return
#     fi

#     local project_code="$(echo "$project_entry" | jq -r ".code")"
#     local project_repo="$(echo "$project_entry" | jq -r ".repo")"
#     local project_dir="$(echo "$project_entry" | jq -r ".dir")"
#     local node_version="$(echo "$project_entry" | jq -r ".versions.node // \"\"")"
#     local php_version="$(echo "$project_entry" | jq -r ".versions.php // \"\"")"

#     # Make sure git repository is cloned
#     if [[ "$project_repo" == "codecommit::"* ]]; then

#         # Default URL repo
#         if [[ ! -d "$HOME/projects/$project_dir" ]]; then
#             print_info "Cloning repository '$project_dir'..."
#             git clone $project_repo "$HOME/projects/$project_dir"
#         else
#             print_success "Repository '$project_dir' already cloned!"
#         fi
#     else
#         # Default URL repo
#         if [[ ! -d "$HOME/projects/$project_dir" ]]; then
#             print_info "Cloning repository '$project_dir'..."

#             git clone git@bitbucket.org:xingredient/$project_repo.git "$HOME/projects/$project_dir"
#         else
#             print_success "Repository '$project_dir' already cloned!"
#         fi
#     fi


#     # Make sure node version is installed
#     if [[ -n "$node_version" ]]; then
#         if [[ "$(nvm ls "$node_version")" == *"N/A"* ]]; then
#             print_info "Installing node v$node_version..."
#             nvm i "$node_version"
#         else
#             print_success "Node v$node_version already installed!"
#         fi

#         nvm use "$node_version" > /dev/null
#     fi

#     # Make sure php version is installed
#     if [[ -n "$php_version" ]]; then
#         brew install "php@$php_version"
#         brew link "php@$php_version"
#         # sudo update-alternatives --set php /usr/bin/php$php_version > /dev/null
#     fi

#     # Make sure npm packages are installed when available
#     if [[ -f "$HOME/projects/$project_dir/package.json" ]]; then
#         if [[ ! -d "$HOME/projects/$project_dir/node_modules" ]]; then
#             print_info "Installing node packages..."
#             cd "$HOME/projects/$project_dir"
#             npm install
#         else
#             print_success "Node packages already installed..."
#         fi
#     fi

#     # Make sure composer packages are installed when available
#     if [[ -f "$HOME/projects/$project_dir/composer.json" ]]; then
#         if [[ ! -d "$HOME/projects/$project_dir/vendor" ]]; then
#             print_info "Installing composer packages..."
#             cd "$HOME/projects/$project_dir"
#             composer install
#         else
#             print_success "Composer packages already installed..."
#         fi
#     fi
# }

# project_start() {
#     local project_entry="$(project_helper_find_config "$1")"

#     if str_empty "$project_entry"; then
#         print_error "No project found with code '$1'"
#         return
#     fi

#     local project_code="$(echo "$project_entry" | jq -r ".code")"
#     local project_repo="$(echo "$project_entry" | jq -r ".repo")"
#     local project_dir="$(echo "$project_entry" | jq -r ".dir")"
#     local node_version="$(echo "$project_entry" | jq -r ".versions.node // \"\"")"
#     local php_version="$(echo "$project_entry" | jq -r ".versions.php // \"\"")"
#     local on_start_commands="$(echo "$project_entry" | jq -r '.config.on_start // empty | .[]')"

#     # # Use the correct php and npm versions if defined
#     # if [[ -n "$php_version" ]]; then
#     #     # sudo update-alternatives --set php /usr/bin/php$php_version > /dev/null
#     #     echo
#     # fi

#     # if [[ -n "$node_version" ]]; then
#     #     nvm use $node_version
#     # fi

#     # Change the directory to the project
#     current_pane=$(tmux display-message -p '#{pane_id}')
#     tmux send-keys -t "$current_pane" "cd $HOME/projects/$project_dir" C-m

#     # Execute the on_start commands
#     while IFS= read -r command; do
#         tmux send-keys -t "$current_pane" "$command" C-m    
#     done <<< "$on_start_commands"
# }

# project_build() {
#     local project_entry="$(project_helper_find_config "$1")"

#     if str_empty "$project_entry"; then
#         print_error "No project found with code '$1'"
#         return
#     fi

#     local project_code="$(echo "$project_entry" | jq -r ".code")"
#     local project_repo="$(echo "$project_entry" | jq -r ".repo")"
#     local project_dir="$(echo "$project_entry" | jq -r ".dir")"
#     local node_version="$(echo "$project_entry" | jq -r ".versions.node // \"\"")"
#     local php_version="$(echo "$project_entry" | jq -r ".versions.php // \"\"")"
#     local on_build_commands="$(echo "$project_entry" | jq -r '.config.on_build // empty | .[]')"

#     # Use the correct php and npm versions if defined
#     if [[ -n "$php_version" ]]; then
#         # sudo update-alternatives --set php /usr/bin/php$php_version > /dev/null
#         echo
#     fi

#     if [[ -n "$node_version" ]]; then
#         nvm use $node_version
#     fi

#     # Change the directory to the project
#     current_pane=$(tmux display-message -p '#{pane_id}')
#     tmux send-keys -t "$current_pane" "cd $HOME/projects/$project_dir" C-m

#     # Execute the on_start commands
#     while IFS= read -r command; do
#         tmux send-keys -t "$current_pane" "$command" C-m    
#     done <<< "$on_build_commands"
# }

# project_go() {
#     local query="$1"

#     # If no query, list projects
#     if [[ -z "$query" ]]; then
#         project_list
#         return 0
#     fi

#     local entry="$(project_helper_find_config "$query")"

#     local project_repo="$HOME/projects/$(echo "$entry" | jq -r ".repo")"
#     local project_dir="$HOME/projects/$(echo "$entry" | jq -r ".dir")"
#     project_repo="$(project_repo_to_name "$project_repo")"
    
#     # Check if the provided project exists
#     if ! str_empty "$entry"; then
#         if [[ -d "$project_dir" ]]; then
#             current_pane=$(tmux display-message -p '#{pane_id}')
#             tmux send-keys -t "$current_pane" "cd $project_dir" C-m
#         else
#             echo "Directory does not exist: $project_dir"
#         fi
#         return
#     fi
    
#     echo "Project '$query' not found. Available projects:"
#     project_list
# }
