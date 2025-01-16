alias project=project_main_command

# Composite command
project_main_command() {
    reset_ifs
    
    composite_define_command "project"
    composite_define_subcommand "list"
    composite_define_subcommand "go" "<projectname>"
    composite_define_subcommand "install"
    composite_define_subcommand "current"
    composite_define_subcommand "info" "<projectname>"
    # composite_define_subcommand "select"

    composite_define_subcommand_description "list" "List all of the registered projects and demos"
    composite_define_subcommand_description "go" "Go to the directory of the project"
    composite_define_subcommand_description "install" "Install the project locally"
    composite_define_subcommand_description "current" "Shows the current project code"

    # if [[ "$LSR_TYPE" == "LSR-FULL" ]]; then
    #     composite_define_subcommand "new"
    #     composite_define_subcommand "delete"
    # fi
    
    composite_handle_subcommand "$@"
}

project_info() {
    local project_code="$1"
    if [[ ! -n "$project_code" ]]; then
        project_code="$(project_current)"
    fi

    # Find the json object belonging to this project
    local project_json1="$(jq -r ".[] | select(.code == \"$project_code\")" "$HOME/projects/projects.json")"
    local project_json2="$(jq -r ".[] | select(.code == \"website-$project_code\")" "$HOME/projects/projects.json")"
    local project_json3="$(jq -r ".[] | select((\"demo-\" + (.client | ascii_downcase) + \"-\" + .code) == \"$project_code\")" "$HOME/projects/demos.json")"
    local project_json4="$(jq -r ".[] | select((\"demo-\" + (.client | ascii_downcase) + \"-\" + .code) == \"demo-$project_code\")" "$HOME/projects/demos.json")"

    local project_json="$project_json1"
    if str_empty "$project_json"; then
        project_json="$project_json2"
    fi

    if str_empty "$project_json"; then
        project_json="$project_json3"
    fi

    if str_empty "$project_json"; then
        project_json="$project_json4"
    fi

    local project_active="$(echo "$project_json" | jq -r ".active")"
    local project_repo="$(echo "$project_json" | jq -r ".repo")"
    local project_code="$(echo "$project_json" | jq -r ".code")"
    local project_websites="$(echo "$project_json" | jq -r "(.sites // []) | to_entries[] | .key")"
    local project_servers="$(echo "$project_json" | jq -r "(.forgeIds // []) | to_entries[] | .key")"

    echo "Project Info for '$project_code'"
    if str_equals "$project_active" "true"; then
        echo "  - Project is active"
    else
        echo "  - Project is inactive"
    fi

    echo "  - Repository: https://bitbucket.org/xingredient/$project_repo/src"

    if ! str_empty "$project_websites"; then
        IFS=' '
        echo 
        echo "Websites: "
        for website in $(echo "$project_websites" | tr '\n' ' '); do
            local url="$(echo "$project_json" | jq -r ".sites.$website")"
            echo "  - website $website: $url"
        done
    fi

    if ! str_empty "$project_servers"; then
        IFS=' '
        echo 
        echo "Forge servers: "
        for server in $(echo "$project_servers" | tr '\n' ' '); do
            local server_id="$(echo "$project_json" | jq -r ".forgeIds.$server.server")"
            local site_id="$(echo "$project_json" | jq -r ".forgeIds.$server.site")"
            echo "  - server $server: https://forge.laravel.com/servers/$server_id/sites/$site_id"
        done
    fi

    local uses_node=false
    if [[ -f "$HOME/projects/$project_repo/package.json" ]]; then
        uses_node=true
    fi

    local uses_composer=false
    if [[ -f "$HOME/projects/$project_repo/composer.json" ]]; then
        uses_composer=true
    fi

    if [[ -f "$HOME/projects/$project_repo/_lsr_scripts/_project.env" ]]; then
        echo
        local node_version_line="$(cat "$HOME/projects/$project_repo/_lsr_scripts/_project.env" | grep "NODE_VERSION=")"
        local node_version="${node_version_line#*=}"

        local php_version_line="$(cat "$HOME/projects/$project_repo/_lsr_scripts/_project.env" | grep "PHP_VERSION=")"
        local php_version="${php_version_line#*=}"

        echo "Technology"

        if str_equals "$uses_node" "true"; then
            echo "  - NodeJS v$node_version"
        fi

        if str_equals "$uses_composer" "true"; then
            echo "  - PHP v$php_version"
        fi
    fi


}

project_install() {
    local project_entry="$(jq -r ".[] | select(.code == \"$1\")" "$HOME/projects/projects.json")"
    local demo_entry="$(jq -r ".[] | select( \"demo-\" + (.client | ascii_downcase) + \"-\" + .code == \"$1\")" "$HOME/projects/demos.json")"

    if [[ -n "$project_entry" ]]; then
        print_info "Creating local copy of project '$1'"

        local project_repo="$(jq -r ".[] | select(.code == \"$1\") | .repo" "$HOME/projects/projects.json")"
        local project_code="$1"
        local project_entry="$(yq e ".projects.$project_code" "$HOME/scripts/local_data/local_settings.yml")"

        # Git repository
        if [[ ! -d "$HOME/projects/$project_repo" ]]; then
            print_info "Cloning repository '$project_repo'..."

            git clone git@bitbucket.org:xingredient/$project_repo.git "$HOME/projects/$project_repo"
        else
            print_success "Repository '$project_repo' already cloned!"
        fi

        # Project registration
        if [[ "$project_entry" == "null" ]]; then
            local yaml_file="$HOME/scripts/local_data/local_settings.yml"
            local project_dir="$HOME/projects/$project_repo"
            print_info "Registering project '$project_code'..."

            yq eval -i ".projects.$project_code = {\"dir\": \"$project_dir\", \"url\": null}" "$yaml_file"
        else
            print_success "Project '$project_code' already registered!"
        fi
    elif [[ -n "$demo_entry" ]]; then
        print_info "Creating local copy of demo '$1'"

        local demo_repo="$(jq -r ".[] | select((\"demo-\" + (.client | ascii_downcase) + \"-\" + .code) == \"$1\") | .repo" "$HOME/projects/demos.json")"
        local demo_code="$1"
        demo_code="${demo_code@L}"

        local project_entry="$(yq e ".projects.$demo_code" "$HOME/scripts/local_data/local_settings.yml")"

        # Git repository
        if [[ ! -d "$HOME/projects/$demo_repo" ]]; then
            print_info "Cloning repository '$demo_repo'..."

            git clone git@bitbucket.org:xingredient/$demo_repo.git "$HOME/projects/$project_repo"
        else
            print_success "Repository '$demo_repo' already cloned"
        fi

        # Project registration
        if [[ "$project_entry" == "null" ]]; then
            local yaml_file="$HOME/scripts/local_data/local_settings.yml"
            local project_dir="$HOME/projects/$demo_repo"
            print_info "Registering project '$demo_code'..."

            yq eval -i ".projects.$demo_code = {\"dir\": \"$project_dir\", \"url\": null}" "$yaml_file"
        else
            print_success "Project '$demo_code' already registered!"
        fi
    else
        print_error "No project or demo found with code '$1'"
        return
    fi
}

# Function to list all available projects, highlighting the current project in green
project_list() {
    local table_rows=()

    local current_proj_code=$(project_current)

    # List all of the project repositories
    local repo_codes="$(jq -r ".[] | .code" "$HOME/projects/projects.json")"
    IFS=$'\n'
    read -r -d '' -a lines <<< "$repo_codes"
    for CODE in "${lines[@]}"; do
        local repo_name="$(jq -r --arg name "$CODE" '.[] | select(.code == $name) | .repo' "$HOME/projects/projects.json")"
        local project_entry="$(yq e ".projects.$CODE" "$HOME/scripts/local_data/local_settings.yml")"

        local COLOR=""
        if [[ "$CODE" == "$current_proj_code" ]]; then
            COLOR="$LSR_COLOR_GREEN"
        fi

        # Repository counts as cloned when:
        # - The a folder with the repo name exists
        # - The project is defined in localsettings
        if [[ -d "$HOME/projects/$repo_name" && "$project_entry" != "null" ]]; then
            table_rows+=("  $LSR_COLOR_GREEN✔$LSR_COLOR_RESET,$COLOR$CODE$LSR_COLOR_RESET,$repo_name")
        else
            table_rows+=("  $LSR_COLOR_RED✖$LSR_COLOR_RESET,$COLOR$CODE$LSR_COLOR_RESET,$repo_name")
        fi
    done

    # List all of the demo repositories
    local demo_names="$(jq -r '.[] | .name' "$HOME/projects/demos.json")"

    IFS=$'\n'
    read -r -d '' -a lines <<< "$demo_names"
    for NAME in "${lines[@]}"; do

        local repo_name="$(jq -r --arg name "$NAME" '.[] | select(.name == $name) | .repo' "$HOME/projects/demos.json")"
        local demo_code="$(jq -r --arg name "$NAME" '.[] | select(.name == $name) | "demo-" + .client + "-" + .code' "$HOME/projects/demos.json")"
        demo_code="${demo_code@L}"

        local project_entry="$(yq e ".projects.$demo_code" "$HOME/scripts/local_data/local_settings.yml")"

        local COLOR=""
        if [[ "$demo_code" == "$current_proj_code" ]]; then
            COLOR="$LSR_COLOR_GREEN"
        fi

        # Repository counts as cloned when:
        # - The a folder with the repo name exists
        # - The project is defined in localsettings
        if [[ -d "$HOME/projects/$repo_name" && "$project_entry" != "null" ]]; then
            table_rows+=("  $LSR_COLOR_GREEN✔$LSR_COLOR_RESET,$COLOR$demo_code$LSR_COLOR_RESET,$repo_name")
        else
            table_rows+=("  $LSR_COLOR_RED✖$LSR_COLOR_RESET,$COLOR$demo_code$LSR_COLOR_RESET,$repo_name")
        fi
    done

    table "Status,Code,Repository" "${table_rows[@]}"
}

project_go() {
    local query="$1"

    # If no query, list projects
    if [[ -z "$query" ]]; then
        project list
        return 0
    fi

    local project_entry="$(jq ".[] | select(.code == \"$query\")" "$HOME/projects/projects.json")"
    local demo_entry="$(jq ".[] | select( \"demo-\" + (.client | ascii_downcase) + \"-\" + .code == \"$query\")" "$HOME/projects/demos.json")"

    local entry=""
    if str_empty "$demo_entry"; then
        entry="$project_entry"
    else
        entry="$demo_entry"
    fi

    # When not found, try with website- or demo- at start
    if str_empty "$entry"; then
        website_query="website-$query"
        demo_query="demo-$query"

        local project_entry="$(jq ".[] | select(.code == \"$website_query\")" "$HOME/projects/projects.json")"
        local demo_entry="$(jq ".[] | select( \"demo-\" + (.client | ascii_downcase) + \"-\" + .code == \"$demo_query\")" "$HOME/projects/demos.json")"

        if str_empty "$demo_entry"; then
            entry="$project_entry"
        else
            entry="$demo_entry"
        fi
    fi

    local project_dir="$HOME/projects/$(echo "$entry" | jq -r ".repo")"
    
    # Check if the provided project exists in the combined projects array
    if ! str_empty "$entry"; then
        if [[ -d "$project_dir" ]]; then
            cd "$project_dir"
        else
            echo "Directory does not exist: $project_dir"
        fi
        return
    fi

    # Handle LSR_EXTRA_PROJECTS
    if [[ -n "$LSR_EXTRA_PROJECTS" ]]; then
        
        # Loop over all of the extra projects
        local extra_project_count=$(lsrlist length LSR_EXTRA_PROJECTS)
        for ((i=0; i<extra_project_count; i++)); do
            local extra_project=$(lsrlist index LSR_EXTRA_PROJECTS "$i")
            local extra_project_name=$(echo "$extra_project" | cut -d':' -f1)
            local extra_project_dir=$(echo "$extra_project" | cut -d':' -f2)

            if [[ "$query" == "$extra_project_name" ]]; then
                cd "$extra_project_dir"
                return
            fi
        done
    fi
    
    echo "Project '$query' not found. Available projects:"
    project list
}

project_current() {
    local cwd
    cwd=$(pwd | xargs)  # Get the current working directory
    local foldername=$(basename "$cwd")

    local current_project="$(jq -r ".[] | select(.repo == \"$foldername\") | .code" "$HOME/projects/projects.json")"
    local current_demo="$(jq -r ".[] | select(.repo == \"$foldername\") | \"demo-\" + (.client | ascii_downcase) + \"-\" + .code" "$HOME/projects/demos.json")"

    echo -n "$(echo "$current_project" | sed -E 's/^(website-|demo-)//')"
    echo -n "$(echo "$current_demo" | sed -E 's/^(website-|demo-)//')"
    echo

    if ! str_empty "$current_project" || ! str_empty "$current_demo"; then
        return 0
    fi

    # Handle LSR_EXTRA_PROJECTS
    if [[ -n "$LSR_EXTRA_PROJECTS" ]]; then
        
        # Loop over all of the extra projects
        local extra_project_count=$(lsrlist length LSR_EXTRA_PROJECTS)
        for ((i=0; i<extra_project_count; i++)); do
            local extra_project=$(lsrlist index LSR_EXTRA_PROJECTS "$i")
            local extra_project_name=$(echo "$extra_project" | cut -d':' -f1)
            local extra_project_dir=$(echo "$extra_project" | cut -d':' -f2)

            if [[ "$cwd" == "$extra_project_dir" ]]; then
                echo -e "$(echo "$extra_project_name" | sed -E 's/^(website-|demo-)//')"
            fi
        done
    fi
}

project_select() {
    projects_output=$(project list)
    projects_list=$(echo "$projects_output" | grep '^ - ' | awk '{sub(/^ - /, ""); if (NR > 1) printf ","; printf "\"%s\"", $0} END {print ""}')
    
    local value=""
    selectable_list "Select a project" value "[$projects_list]"
    project go $value
}

# Function to add a new project to local_settings.yml
project_new() {
    local project_name="$1"
    local project_dir="$2"
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"

    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        print_error "project new is LSR-FULL only"
        return
    fi

    if [[ -z "$project_name" ]]; then
        echo "Usage: project new <project_name> [project_directory]"
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
project_delete() {
    local project_name="$1"
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"

    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        print_error "project delete is LSR-FULL only"
        return
    fi

    if [[ -z "$project_name" ]]; then
        echo "Usage: project delete <project_name>"
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
