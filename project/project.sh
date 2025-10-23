source "$HOME/.lsr_core/core/lsr.core.sh"

[ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"

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

LSR_COMMAND_SET_HELP "project.prepare" "Sets correct node and php versions for this project"
project_prepare() {
    local project_json="$(project_json)"
    local project_node_version="$(echo "$project_json" | jq -r ".versions.node")"
    local project_php_version="$(echo "$project_json" | jq -r ".versions.php")"

    if [[ "$project_node_version" != "null" ]]; then
        print_info "Project uses node $project_node_version"
    fi

    if [[ "$project_php_version" != "null" ]]; then
        print_info "Project uses php $project_php_version"
    fi

    # Set correct node version
    if [[ "$project_node_version" != "null" ]]; then
        nvm use "$project_node_version"
    fi

    # Set correct php version
    if [[ "$project_php_version" != "null" ]]; then
        brew unlink php
        brew link "php@$project_php_version"
    fi
}

LSR_COMMAND_SET_HELP "project.install" "Completely installs the project from scratch"
project_install() {
    local repo_prefix="git@bitbucket.org:xingredient/"
    local env_folder="$HOME/projects/env_files"

    if [[ "$(ls)" != "" ]]; then
        print_error "Can only install project from scratch, but this folder contains files"
        return
    fi

    # Cloning repository
    local project_json="$(project_json)"
    local project_repo="$(echo "$project_json" | jq -r ".repo")"
    local project_code="$(echo "$project_json" | jq -r ".code")"
    local repo_url="$repo_prefix$project_repo.git"    
    local post_clone_commands="$(echo "$project_json" | jq -r "(.post_clone_commands // [])[]")"
    
    print_info "cloning repository $repo_url"

    git clone $repo_url . > /dev/null

    # Place .env file
    if [[ -f "$env_folder/$project_code.env" ]]; then
        print_info "Copying over backup .env file"
        cp "$env_folder/$project_code.env" .env
    else
        print_warn "not able to find $project_code.env file backup"
    fi

    echo "$post_clone_commands" | while IFS= read -r command_to_run; do
        print_info "post clone command: $command_to_run"
        
        # Execute the command string
        eval "$command_to_run"
        
        EXIT_CODE=$?
    done

    # Make sure we use the correct node and composer versions
    project_prepare

    # Install node packages
    if [[ -f "./package.json" ]]; then
        if [[ ! -d "./node_modules" ]]; then
            print_info "Installing node packages..."
            npm i --silent > /dev/null
        fi
    fi

    # Install vendor packages
    if [[ -f "./composer.json" ]]; then
        if [[ ! -d "./vendor" ]]; then
            print_info "Installing composer packages..."
            composer i -n > /dev/null
        fi
    fi

    print_info "All packages installed!"

    # If sail is installed, create the sail containers and run migrations, and link storage
    if [[ -f "./vendor/bin/sail" ]]; then
        ./vendor/bin/sail create
        ./vendor/bin/sail start
        ./vendor/bin/sail artisan storage:link
        sleep 5 # Sleep to make sure the migration can succesfully happen and is not too early
        ./vendor/bin/sail artisan migrate
        
        # Create filament user if filament is installed
        local filament_package="$(cat composer.json | grep filament/filament)"
        if [[ $filament_package != "" ]]; then
            print_info "Creating filament user"
            ./vendor/bin/sail artisan make:filament-user --name=admin --email=admin@x-ingredient.nl --password="password"
        fi
    fi
}

LSR_COMMAND_SET_HELP "project.remove" "Deinstall the project by removing the project files & docker containers"
project_remove() {

    # If project contains sail, we must make sure the container is removed first
    if [[ -f ./vendor/bin/sail ]]; then

        # If docker deamon is not running, start it
        print_info "checking docker containers..."
        docker info > /dev/null 2>&1 || {
            print_info "docker deamon not running, attempting to start..."

            open -a Docker --args --user-initiated > /dev/null 2>&1

            i=0
            while ! docker info > /dev/null 2>&1; do
                # Add a visual wait indicator
                printf "."
                sleep 1
                i=$((i+1))
                # Optional: Add a timeout to prevent an infinite loop
                if [ $i -ge 60 ]; then
                    print_error "docker daemon failed to start after 60 seconds."
                    return
                fi
            done
            echo "" # Print newline due to docker startup printing
        }

        # If container exists, remove it
        local container_ids="$(./vendor/bin/sail ps -aq)"
        if [[ "$container_ids" != "" ]]; then
            print_info "removing docker containers..."
            ./vendor/bin/sail down -v > /dev/null
        else
            print_info "docker containers were already removed"
        fi
    fi
    
    # Removing all project files
    local rm_executable="$(which rm)"
    print_info "removing project files..."
    $rm_executable -rf *
    $rm_executable -rf .??*

    print_success "project deinstalled"
}

LSR_COMMAND_SET_HELP "project.open-repo" "Open repository of this project"
project_open_repo() {
    local default_repo_prefix="https://bitbucket.org/xingredient"

    local project_json="$(project_json)"
    local repo_name="$(echo "$project_json" | jq -r ".repo")"
    local repo_url="$default_repo_prefix/$repo_name"

    open "$repo_url"
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
