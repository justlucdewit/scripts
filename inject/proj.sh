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