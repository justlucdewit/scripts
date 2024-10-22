# TODO: when deleting a proj that is defined in definitions.sh, notify that
# It is impossible to delete that one

# Declare the array that will hold the merged projects
declare -gA combined_projects

# Function to add a new project to local_settings.yml
nproj() {
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
            yq eval ".projects[\"$project_name\"] = \"$project_dir\"" -i "$yaml_file"
            echo "Added project '$project_name' to local_settings."
        fi
    else
        echo "YAML file not found: $yaml_file"
    fi
}

# Function to remove a project from local_settings.yml
rproj() {
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
        done < <(yq eval '.projects | to_entries | .[] | .key + "=" + .value' "$yaml_file")
    fi
}

# Function to sync the original projects with the YAML projects into combined_projects
sync_projects() {
    # Load projects from YAML
    load_yaml_projects

    # Reset the combined_projects array
    combined_projects=()

    # Add all original projects to the combined_projects array
    for key in "${!projects[@]}"; do
        combined_projects["$key"]="${projects[$key]}"
    done

    # Add or override with projects from the yaml_projects array
    for key in "${!yaml_projects[@]}"; do
        combined_projects["$key"]="${yaml_projects[$key]}"
    done
}

# Function to list all available projects, highlighting the current project in green
list_projects() {
    sync_projects  # Sync the combined projects array
    local current_dir=$(pwd)
    local green='\033[0;32m'
    local reset='\033[0m'

    echo "Available projects:"
    local show_dirs="$1"
    for key in "${!combined_projects[@]}"; do
        # Determine if the current project is the active one
        if [[ "${combined_projects[$key]}" == "$current_dir" ]]; then
            # Highlight the current project in green
            if [[ "$show_dirs" == true ]]; then
                echo -e "${green} - $key: ${combined_projects[$key]}${reset}"
            else
                echo -e "${green} - $key${reset}"  # Green highlight for the project name
            fi
        else
            # Regular output for other projects
            if [[ "$show_dirs" == true ]]; then
                echo " - $key: ${combined_projects[$key]}"
            else
                echo " - $key"
            fi
        fi
    done
}

proj() {
    sync_projects  # Sync the combined projects array

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
        if [[ -n "${combined_projects[$1]}" ]]; then
            if [[ -d "${combined_projects[$1]}" ]]; then
                cd "${combined_projects[$1]}" || echo "Failed to navigate to ${combined_projects[$1]}"
            else
                echo "Directory does not exist: ${combined_projects[$1]}"
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
