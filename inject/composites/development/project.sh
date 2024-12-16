alias project=project_main_command

# Composite command
project_main_command() {
    reset_ifs
    
    composite_define_command "project"
    composite_define_subcommand "list"
    composite_define_subcommand "go"
    composite_define_subcommand "current"
    composite_define_subcommand "select"

    if [[ "$LSR_TYPE" == "LSR-FULL" ]]; then
        composite_define_subcommand "new"
        composite_define_subcommand "delete"
    fi

    composite_handle_subcommand $@
}

# Function to list all available projects, highlighting the current project in green
project_list() {
    local current_dir=$(pwd)
    local current_project=$(project current)
    local green='\033[0;32m'
    local reset='\033[0m'

    echo "Available projects:"
    lseval '.projects | to_entries | .[].key' | while read -r key; do
        if [[ "$current_project" == "$key" ]]; then
            echo -e "${green} - $key${reset}"
        else
            echo -e " - $key"
        fi
    done

    # Handle LSR_EXTRA_PROJECTS
    if [[ -n "$LSR_EXTRA_PROJECTS" ]]; then
        
        # Loop over all of the extra projects
        local extra_project_count=$(lsrlist length LSR_EXTRA_PROJECTS)
        for ((i=0; i<extra_project_count; i++)); do
            local extra_project=$(lsrlist index LSR_EXTRA_PROJECTS "$i")
            local extra_project_name=$(echo "$extra_project" | cut -d':' -f1)
            local extra_project_dir=$(echo "$extra_project" | cut -d':' -f2)

            if [[ "$current_project" == "$extra_project_name" ]]; then
                echo -e "${green} - $extra_project_name${reset}"
            else
                echo -e " - $extra_project_name"
            fi
        done
    fi
}

project_go() {
    local query="$1"

    # If no query, list projects
    if [[ -z "$query" ]]; then
        project list
        return 0
    fi

    local project_dir="$(lseval ".projects | to_entries | map(select(.key == \"$query\")) | .[0].value.dir")"
    
    # Check if the provided project exists in the combined projects array
    if [[ "$project_dir" != "null" && "$project_dir" != "" ]]; then
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

    local current_project="$(lseval ".projects | to_entries | map(select(.value.dir == \"$cwd\")) | .[0].key")"
    if [[ "$current_project" != "null" && "$current_project" != "" ]]; then
        echo "$current_project";
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

            if [[ "$cwd" == "$extra_project_dir" ]]; then
                echo -e "$extra_project_name"
            fi
        done
    fi
}

project_select() {
    projects_output=$(project list)
    projects_list=$(echo "$projects_output" | grep '^ - ' | awk '{sub(/^ - /, ""); if (NR > 1) printf ","; printf "%s", $0} END {print ""}')
    
    local value=""
    selectable_list "Select a project" value "$projects_list"
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
