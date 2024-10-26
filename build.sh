# LSR v1.1
# Local build (18:03 26/10/2024)
# Includes LSR modules:
# - /home/lucdewit/scripts/inject/proj.sh
# - /home/lucdewit/scripts/inject/compile.sh
# - /home/lucdewit/scripts/inject/definitions.sh
# - /home/lucdewit/scripts/inject/aliases.sh
# - /home/lucdewit/scripts/inject/docker_helpers.sh
# - /home/lucdewit/scripts/inject/git_helpers.sh
# - /home/lucdewit/scripts/inject/laravel.sh
# - /home/lucdewit/scripts/inject/local_settings.sh
# - /home/lucdewit/scripts/inject/tmux_helpers.sh
# - /home/lucdewit/scripts/inject/version_management.sh
# - /home/lucdewit/scripts/inject/vim.sh
# - /home/lucdewit/scripts/inject/work.sh
# - /home/lucdewit/scripts/inject/other.sh

#################################
# Start of LSR module #1        #
# Injected LSR module: proj.sh  #
# Number of lines: 256          #
# Filesize: 7.94 KB             #
#################################
# TODO: when deleting a proj that is defined in definitions.sh, notify that
# It is impossible to delete that one

# Declare the array that will hold the merged projects
declare -gA combined_projects

alias cproj=current_project
alias proj=project
alias p=project
alias rproj=remove_project
alias nproj=new_project
alias sprojurl=set_project_url
alias gprojurl=get_project_url
alias rprojurl=remove_project_url


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

####################################
# Start of LSR module #2           #
# Injected LSR module: compile.sh  #
# Number of lines: 147             #
# Filesize: 5.13 KB                #
####################################
source "$HOME/scripts/helpers.sh"

# Global list of scripts to compile
scripts_to_compile=(
    "proj"
    "compile"
    "definitions"
    "aliases"
    "docker_helpers"
    "git_helpers"
    "laravel"
    "local_settings"
    "tmux_helpers"
    "version_management"
    "vim"
    "work"
    "other"
    # "cfind" # WIP
)

alias lcompile=lsr_compile

print_info "LSR has been loaded in current session"

lsr_compile() {
    print_info "Starting re-compilation of LSR"
    local build_file="$HOME/scripts/build.sh"
    local minimized_build_file="$HOME/scripts/build.min.sh"
    local SETTINGS_FILE=~/scripts/_settings.yml
    local NAME=$(yq e '.name' "$SETTINGS_FILE")
    local MAJOR_VERSION=$(yq e '.version.major' "$SETTINGS_FILE")
    local MINOR_VERSION=$(yq e '.version.minor' "$SETTINGS_FILE")
    local FULL_VERSION=v$MAJOR_VERSION.$MINOR_VERSION
    local SCRIPT_PREFIX="$HOME/scripts/inject/"

    # Make buildfile if it doesn't exist, else clear it
    if [[ -f "$build_file" ]]; then
        > "$build_file"
    else
        touch "$build_file"
    fi

    {
        echo "# LSR $FULL_VERSION"
        echo "# Local build ($(date +'%H:%M %d/%m/%Y'))"
        echo "# Includes LSR modules:"
    } >> "$build_file"

    for script in "${scripts_to_compile[@]}"; do
        if [[ -f "$SCRIPT_PREFIX$script.sh" ]]; then
            echo "# - $SCRIPT_PREFIX$script.sh" >> "$build_file"  # Add a newline for separation
        else
            print_info "Warning: $script does not exist, skipping."
        fi
    done

    echo "" >> "$build_file"  # Add a newline for separation

    local i=1

    # Loop through the global array and compile the scripts
    for script in "${scripts_to_compile[@]}"; do
        if [[ -f "$SCRIPT_PREFIX$script.sh" ]]; then
            local script_line_count=$(get_line_count "$SCRIPT_PREFIX$script.sh")
            local script_filesize=$(get_filesize "$SCRIPT_PREFIX$script.sh")
            print_info " - Compiling $script.sh ($script_filesize/$script_line_count lines)"
            
            local module_index_line="# Start of LSR module #${i} "
            ((i++))
            local module_name_line="# Injected LSR module: $script.sh "
            
            local line_count_line="# Number of lines: $script_line_count "
            local filesize_line="# Filesize: $script_filesize "
            
            # Function to calculate the length of a string
            get_length() {
                echo "${#1}"
            }

            # Determine the maximum length of the content (excluding hashtags)
            max_content_length=$(get_length "$module_index_line")
            for line in "$module_name_line" "$line_count_line" "$filesize_line"; do
                line_length=$(get_length "$line")
                if [[ $line_length -gt $max_content_length ]]; then
                    max_content_length=$line_length
                fi
            done

            # Add space for the right-side hashtag
            max_line_length=$((max_content_length + 2)) # +2 for the hashtags on each side

            # Make a horizontal line exactly long enough
            horizontal_line=$(printf "#%0.s" $(seq 1 $max_line_length))

            # Function to pad the lines with spaces and add the right border hashtag
            pad_line() {
                local content="$1"
                local padding_needed=$((max_line_length - $(get_length "$content") - 1)) # -1 for the ending hashtag
                printf "%s%${padding_needed}s#" "$content" ""
            }

            {
                echo "$horizontal_line"
                echo "$(pad_line "$module_index_line")"
                echo "$(pad_line "$module_name_line")"
                echo "$(pad_line "$line_count_line")"
                echo "$(pad_line "$filesize_line")"
                echo "$horizontal_line"
            } >> "$build_file"

            cat "$SCRIPT_PREFIX$script.sh" >> "$build_file"
            echo "" >> "$build_file"  # Add a newline for separation
        fi
    done

    $build_file_size

    print_info "Finished recompiling LSR at $build_file"
    print_info "Total final build.sh size: $(get_filesize "$build_file")"
    print_info "Total final build.sh lines: $(get_line_count "$build_file")"

    # Minimization
    print_empty_line
    print_info "Generating minimized build file"

    local remove_comment_lines='^\s*#'  # Matches lines that are just comments
    local trim_whitespace='^\s*|\s*$'   # Matches leading and trailing whitespace on each line
    local remove_empty_lines='^$'       # Matches empty lines
    
    # Check if minified file exists, if not, create it
    if [[ ! -f $minimized_build_file ]]; then
        touch "$minimized_build_file"
    fi

    # Copy original script to the minified script file
    cp "$build_file" "$minimized_build_file"

    # Apply regex transformations one by one
    sed -i "/$remove_comment_lines/d" "$minimized_build_file"
    sed -i "s/$trim_whitespace//g" "$minimized_build_file"
    sed -i "/$remove_empty_lines/d" "$minimized_build_file"

    print_info "Total final build.min.sh size: $(get_filesize "$minimized_build_file")"
    print_info "Total final build.min.sh lines: $(get_line_count "$minimized_build_file")"

    reload_bash
}

########################################
# Start of LSR module #3               #
# Injected LSR module: definitions.sh  #
# Number of lines: 14                  #
# Filesize: 343 B                      #
########################################
unset -v projects
declare -gA projects=(
    ["scripts"]="$HOME/scripts" # Add scripts as a hardcoded project
)

unset -v user_map
declare -gA user_map=(
    ["CK"]="Cem"
    ["Luc de Wit"]="Luc"
    ["Reinout Boelens"]="Reinout"
    ["Eli"]="Eli"
    ["Maurits van Mierlo"]="Maurits"
    ["Bram Gubbels"]="Bram"
    ["riyadbabouri"]="Riyad"
)
####################################
# Start of LSR module #4           #
# Injected LSR module: aliases.sh  #
# Number of lines: 28              #
# Filesize: 793 B                  #
####################################
# LSR Module that contains standalone aliases

reload_bash() {
    source ~/.bashrc
    print_success '~/.bashrc reloaded!'
}

backup() {
    local backup_location="$1-backup"
    cp $1 $backup_location -r
}

alias hosts='powershell.exe -Command "Start-Process \"C:\Program Files\Sublime Text\sublime_text.exe\" -ArgumentList \"C:\Windows\System32\Drivers\etc\hosts\" -Verb RunAs"'
alias refreshdns='powershell.exe -Command "ipconfig /flushdns"'
alias c='clear'
alias cf='cfind'
alias today='work --date=today'
alias yesterday='work --date=yesterday'
alias l="ls -la"
alias rb="reload_bash"
alias files="explorer.exe ."
alias subl='"/mnt/c/Program Files/Sublime Text/sublime_text.exe"'

unalias joke 2>/dev/null
joke() {
    curl -H "Accept: text/plain" https://icanhazdadjoke.com/
    echo
}

###########################################
# Start of LSR module #5                  #
# Injected LSR module: docker_helpers.sh  #
# Number of lines: 158                    #
# Filesize: 5.45 KB                       #
###########################################
# Define color codes
LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

docklist() {
    echo -e "${BLUE}Container Overview:${RESET}"
    
    # Temporary associative array to store the first container status for each project
    declare -A projects
    declare -A project_status

    # Collect container information and group by project label
    while IFS= read -r container; do
        container_id=$(echo "$container" | awk '{print $1}')
        container_name=$(echo "$container" | awk '{print $2}')
        project_name=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' "$container_id")
        status=$(docker inspect --format '{{.State.Status}}' "$container_id")

        if [[ -n "$project_name" ]]; then
            projects["$project_name"]+="$container_id:$container_name;"
            # Store the status of the first container found for the project
            if [[ -z "${project_status[$project_name]}" ]]; then
                project_status["$project_name"]="$status"
            fi
        fi
    done < <(docker ps -aq)  # Read all container IDs

    # Determine the longest project name
    longest_name=0
    for project in "${!projects[@]}"; do
        length=${#project}
        if (( length > longest_name )); then
            longest_name=$length
        fi
    done

    # Print the headers with dynamic width
    printf "${YELLOW}%-5s\t%-${longest_name}s\t%s\n${RESET}" "Index" "Project Name" "Status"  # Fixed-width headers

    # Print the grouped container information
    local index=1
    for project in "${!projects[@]}"; do
        if [[ "${project_status[$project]}" = "running" ]]; then
            printf "${GREEN}%-5s\t%-${longest_name}s${LIGHT_GREEN}\t%s\n${RESET}" "$index" "$project" "${project_status[$project]}"
        else
            printf "${GREEN}%-5s\t%-${longest_name}s${RED}\t%s\n${RESET}" "$index" "$project" "${project_status[$project]}"
        fi
        
        ((index++))
    done
}

dockstart() {
    if [ -z "$1" ]; then
        print_error "Usage: dockstart <number>"
        return 1
    fi

    # Collect unique project names in an array
    mapfile -t project_names < <(docker ps -aq --filter "label=com.docker.compose.project" | xargs docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u)

    # Get the project name based on the specified index
    project_name="${project_names[$(( $1 - 1 ))]}"  # Convert to zero-based index

    if [ -z "$project_name" ]; then
        print_error "No project found at index $1."
        return 1
    fi

    # Get the container IDs for the specified project
    container_ids=$(docker ps -aq --filter "label=com.docker.compose.project=$project_name")

    if [ -z "$container_ids" ]; then
        print_error "No stopped containers found for project '$project_name'."
        return 1
    fi

    # Start all containers belonging to the project
    print_success "Starting containers for project: $project_name"
    docker start $container_ids
}

# Stop a Docker container by its index (number)
dockstop() {
    if [ -z "$1" ]; then
        print_error "Usage: dockstop <number>"
        return 1
    fi

    # Get the project name based on the index
    project_name=$(docker ps --format '{{.ID}}' | xargs docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u | sed -n "1p")
    print_debug $project_name
    if [ -z "$project_name" ]; then
        print_error "No project found at index $1."
        return 1
    fi

    # Get the container IDs for the specified project
    container_ids=$(docker ps -q --filter "label=com.docker.compose.project=$project_name")

    if [ -z "$container_ids" ]; then
        print_error "No running containers found for project '$project_name'."
        return 1
    fi

    # Stop all containers belonging to the project
    print_success "Stopping containers for project: $project_name"
    docker stop $container_ids
}

# Remove a Docker container by its index (number)
dockremove() {
    if [ -z "$1" ]; then
        print_error "Usage: dockremove <number>"
        return 1
    fi

    container_id=$(docker ps -a --format '{{.ID}}' | sed -n "${1}p")  # Get the container ID at the specified index
    if [ -z "$container_id" ]; then
        print_error "No container found at index $1."
        return 1
    fi

    print_success "Removing container: $container_id"
    docker rm "$container_id"
}

dockrestart() {
    # Check if Docker is running
    if docker info >/dev/null 2>&1; then
        print_info "Docker is currently running."
        
        running_containers=$(docker ps -q)
        if [ -n "$running_containers" ]; then
            print_info "Stopping all running containers..."
            docker stop $running_containers
        fi

        print_info "Restarting Docker Desktop..."
        powershell.exe -Command "Get-Process | Where-Object { \$_.Name -like \"*docker*\" } | Stop-Process -Force"
        sleep 5  # Wait for a moment before starting it again
        powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
    else
        print_info "Docker is not running. Starting Docker Desktop..."
        powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
        sleep 20
    fi

    # Confirm the action
    if docker info >/dev/null 2>&1; then
        print_success "Docker is now running."
    else
        print_error "Failed to start Docker."
    fi
}
########################################
# Start of LSR module #6               #
# Injected LSR module: git_helpers.sh  #
# Number of lines: 27                  #
# Filesize: 895 B                      #
########################################
# Define a function to check if you're in a Git repo and show the current branch
parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -n $branch ]]; then
        echo "$branch"
    fi
}

# Display your current branch name and commit count:
git_info() {
    branch=$(git rev-parse --abbrev-ref HEAD)
    commits=$(git rev-list --count HEAD)
    echo "On branch: $branch, commits: $commits"
}

alias gitlog='git log --pretty=format:"%C(green)%h %C(blue)%ad %C(red)%an%C(reset): %C(yellow)%s%C(reset)" --color --date=format:"%d/%m/%Y %H:%M"'
alias s='git status'
alias co='git checkout'
alias br='git branch --all'
alias ci='git commit'
alias st='git stash'

# alias rb='git rebase'
# alias rba='git rebase --abort'
# alias rbc='git rebase --continue'
alias delete='git branch -d'
alias d="!f() { git branch -d $1 && git push origin --delete $1; }; f"
####################################
# Start of LSR module #7           #
# Injected LSR module: laravel.sh  #
# Number of lines: 215             #
# Filesize: 5.82 KB                #
####################################
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

switch() {
    local project=$1

    # Usage printing
    if [[ -z $project ]]; then
        echo "Usage: switch <projectname>"
        return 0
    fi

    # Check if project exists
    local failedSwitching=$(proj "$project" | grep -q "Project not found. Available projects:" && echo true || echo false)

    # Print error
    if [[ $failedSwitching == true ]]; then
        print_error "Cannot switch to project '$project' because it does not exist"
        proj
        return 1
    fi

    stop
    start $project
}

stop() {
    # Close everything except the current terminal
    print_info "Closing npm pane"
    run_in_pane 1 C-c
    sleep 1
    tclose 1
    print_info "Closing sail pane"
    run_in_pane 0 C-c
    sleep 3
    tclose 0
    cd ~
}

start() {
    # If argument is given, go to that project
    local project=$1
    local failedSwitching=$(proj "$project" | grep -q "Project not found. Available projects:" && echo true || echo false)

    # Failed switching to project
    if [[ $failedSwitching == true ]]; then
        print_error "Cannot start project '$project' because it does not exist"
        proj
        return 1
    fi

    # Jump to project if needed
    if [[ -n "$project" ]]; then
        proj "$project"
    else # No project was given
        # If current dir is not a project, dont continue
        project=$(cproj)
        if [[ -z "$project" ]]; then
            print_error "Cant start because current dir is not a defined project"
            return 1
        fi
    fi

    clear

    create_start_layout

    run_in_pane 0 "clear"
    run_in_pane 1 "clear"
    run_in_pane 2 "clear"
    
    run_in_pane 2 el 20
    run_in_pane 2 clear
    run_in_pane 2 tls

    # TODO: what if no package.json is available?
    # TODO: what if no laravel available?
    # TODO: open URL if available

    # Get the first available npm script
    npm_script=$(get_first_npm_script)

    # Start npm, make sure no browsers get opened
    if grep -q "\"$npm_script\": \"vite" package.json; then
        print_info "starting npm with 'npm run $npm_script -- --open=false'"
        run_in_pane 1 "npm run $npm_script -- --open=false"
    else
        print_info "starting npm with 'npm run $npm_script'"
        run_in_pane 1 "npm run $npm_script"
    fi

    # Open URL if available
    local projurl=$(get_project_url)
    if [[ "$projurl" == "null" ]]; then
        # Start sail
        print_info "starting sail..."
        run_in_pane 0 sail up
    else
        run_in_pane 2 "(sleep 5; explorer.exe $projurl) &" 
        print_info "starting sail..."
        run_in_pane 0 sail up
    fi

    return 0
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
###########################################
# Start of LSR module #8                  #
# Injected LSR module: local_settings.sh  #
# Number of lines: 182                    #
# Filesize: 5.13 KB                       #
###########################################
local_settings_file="$HOME/scripts/local_data/local_settings.yml"
local_settings_dir="$(dirname "$local_settings_file")"

alias lsget="localsettings_get"
alias lsset="localsettings_set"
alias lseval="localsettings_eval"

localsettings_ensureexists() {
    local field="$1"

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    local value=$(yq e "$field // \"\"" "$local_settings_file")

    # Create it if it does not exist
    if [[ -z "$value" ]]; then
        yq e -i "$field = null" "$local_settings_file"
        localsettings_reformat
    fi
}

localsettings_eval() {
    local command="."

    if [[ -n $1 ]]; then
        command="$1"
    fi

    yq e -P "$command" "$local_settings_file"
}

localsettings_get() {
    local allow_create=false
    local field="."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --allow-create)
                allow_create=true
                shift
                ;;
            *)
                field="$1"
                shift
                ;;
        esac
    done

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    if $allow_create; then
        localsettings_ensureexists "$field"
    fi
    
    yq e -P "$field" "$local_settings_file"
}

localsettings_set() {
    local allow_create=false
    local field=""
    local value=""
    local unquoted=false

    # Display help message
    show_help() {
        print_normal "Usage: localsettings_set [OPTIONS] FIELD VALUE"
        print_normal "Set a value in the local settings file."
        print_normal ""
        print_normal "Options:"
        print_normal "  -a, --allow-create   Create the field if it doesn't exist."
        print_normal "  -u, --unquoted       Set the value without quotes."
        print_normal "  -h, --help           Display this help message."
        print_normal ""
        print_normal "Examples:"
        print_normal "  localsettings_set --allow-create .projects.aa '5'  # Set with quotes"
        print_normal "  localsettings_set --unquoted .projects.aa 5        # Set without quotes"
        print_normal "  localsettings_set .projects.aa '5'                  # Set with quotes"
        print_normal "  localsettings_set --help                             # Display help"
    }

    # Parse options using getopts
    while getopts "auh" opt; do
        case "$opt" in
            a) allow_create=true ;;
            u) unquoted=true ;;
            h) show_help; return 0 ;;
            \?) print_normal "Invalid option: -$OPTARG" >&2; return 1 ;;
            :) print_normal "Option -$OPTARG requires an argument." >&2; return 1 ;;
        esac
    done

    # Shift off the options processed by getopts
    shift $((OPTIND - 1))

    # Now handle long options manually
    for arg in "$@"; do
        case "$arg" in
            --allow-create)
                allow_create=true
                ;;
            --unquoted)
                unquoted=true
                ;;
            --help)
                show_help
                return 0
                ;;
            *)
                # Capture field and value
                if [[ -z "$field" ]]; then
                    field="$arg"  # First non-flag argument is the field
                elif [[ -z "$value" ]]; then
                    value="$arg"  # Second non-flag argument is the value
                else
                    print_normal "Error: Too many arguments." >&2
                    return 1
                fi
                ;;
        esac
    done

    # Check that both field and value are provided
    if [[ -z "$field" || -z "$value" ]]; then
        print_normal "Error: FIELD and VALUE are required." >&2
        return 1
    fi

    # Ensure field starts with a dot
    if [[ "$field" != .* ]]; then
        field=".$field"
    fi

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    # Ensure the field exists, conditionally
    if $allow_create; then
        localsettings_ensureexists "$field"
    fi

    print_normal "$unquoted"

    # Set the value
    if [[ $unquoted == "true" ]]; then
        # Set without quotes
        print_normal "YEEE"
        print_normal "yq e -i \"$field=$value\" \"$local_settings_file\""
        yq e -i "$field=$value" "$local_settings_file"
    else
        # Set with quotes
        yq e -i "$field=\"$value\"" "$local_settings_file"
    fi
}

yq_validate_only_lookup() {
    local field="$1"

    # Allow just a dot to return the entire structure
    if [[ "$field" == "." ]]; then
        return 0  # Valid case for root access
    fi

    # Regular expression to match valid field patterns
    if [[ ! "$field" =~ ^\.[a-zA-Z_][a-zA-Z0-9_.]*(\[[0-9]+\])?(\.[a-zA-Z_][a-zA-Z0-9_.]*(\[[0-9]+\])?)*$ ]]; then
        print_error "Invalid field format '${field}'. Only lookup notation is allowed (e.g., .projects or .projects.example).\n"
        return 1  # Exit with an error
    fi

    return 0
}

localsettings_reformat() {
    yq e -P '.' -i "$local_settings_file"
}
#########################################
# Start of LSR module #9                #
# Injected LSR module: tmux_helpers.sh  #
# Number of lines: 429                  #
# Filesize: 13.34 KB                    #
#########################################
# TODO: Fix bug where when pane 1 is closed, pane 2 will become 1 and thus take its name

DEBUG_CACHE_WRITING=false
INDENT="    "
INACTIVE_LIST_ITEM=" - "
ACTIVE_LIST_ITEM=" * "
PANE_NAME_FILE="$HOME/scripts/local_data/tmp/tmux_pane_names.txt"

alias spf="sync_pane_file"

sync_pane_file() {
    > $PANE_NAME_FILE
    save_pane_names
}

get_pane_id() {
    if [ -z "$1" ]; then
        echo "Usage: get_pane_id <pane_number>"
        return 1
    fi

    local pane_number="$1"

    # Ensure the pane number is a valid number (for safety)
    if [[ ! "$pane_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Pane number must be a number."
        return 1
    fi

    # Get the pane ID corresponding to the pane number
    local pane_id=$(tmux list-panes -F "#{pane_index} #{pane_id}" | awk -v num="$pane_number" '$1 == num {print $2}'  | tr -d '%')

    if [ -z "$pane_id" ]; then
        echo "No pane found with number: $pane_number"
        return 1
    fi

    # Output the pane ID
    echo "$pane_id"
}

get_pane_number() {
    if [ -z "$1" ]; then
        echo "Usage: get_pane_number <pane_id_without_percentage>"
        return 1
    fi

    local pane_id="$1"
    
    # Ensure the pane ID is a valid number (for safety)
    if [[ ! "$pane_id" =~ ^[0-9]+$ ]]; then
        echo "Error: Pane ID must be a number."
        return 1
    fi

    local pane_index=$(tmux list-panes -F "#{pane_id},#{pane_index}" | grep "%${pane_id}" | cut -d',' -f2)

    if [ -z "$pane_index" ]; then
        echo "No pane found with ID: %$pane_id"
        return 1
    fi

    # Output the pane index
    echo "$pane_index"
}

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
alias wk="tmux kill-window" # Close window
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

    local pane_name

    if [[ $# -eq 1 ]]; then
        # Only one argument provided: it's the new name, use the current pane
        pane_name=$1
        current_pane=$(tmux display-message -p '#D' | tr -d '%')  # Get the current pane id
    elif [[ $# -eq 2 ]]; then
        # Two arguments provided: first is the pane index, second is the new name
        current_pane=$(get_pane_id $1)
        echo "going for pane $target_pane"
        pane_name=$2
    else
        echo "Usage: rename_pane [<pane_number>] <new_name>"
        return 1
    fi

    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')

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
    current_pane_id=$(tmux display -p '#D' | tr -d '%')  # Unique pane ID

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
    active_pane=$(tmux display-message -p '#D' | tr -d '%')

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
                pane_id=$(echo "$pane" | cut -d':' -f1 | xargs | tr -d '%')  # Get the pane number
                pane_number=$(get_pane_number $pane_id)

                # Create a unique key for the pane
                pane_key="${session_name}:${window_number}:${pane_id}"
                pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}

                # Check if pane is active
                if [ "$session_name" == "$active_session" ] && [ "$window_number" == "$active_window" ] && [ "$pane_id" == "$active_pane" ]; then
                    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $pane_id($pane_number): $pane_name\e[0m"
                else
                    echo -e "${INDENT}${INDENT}${INACTIVE_LIST_ITEM}\e[1;33mPane $pane_id($pane_number): $pane_name\e[0m"
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

run_in_pane_until_finished() {
    load_pane_names

    # Get the target pane number and command
    local target_pane=$1
    shift
    local command="$*"

    # Run the command in the target pane
    tmux send-keys -t $target_pane "$command" C-m

    # Wait for the pane to stop showing activity (becomes idle)
    while true; do
        # Capture pane content and check for any command prompt (indicating readiness)
        local pane_output=$(tmux capture-pane -pt $target_pane -S - )

        # If the last line is a prompt (customize based on your shell prompt), break the loop
        if [[ $pane_output =~ \$$  ]]; then  # Example: match shell prompt ending with "$ "
            break
        fi

        # Sleep to avoid rapid polling
        sleep 1
    done
}

# Print the current pane number
alias tcur="tmux display-message -p 'Current pane number: #D'"

# Use this to start tmux:
#   - Creates new session if none found
#   - if session found, use that one
t() {
    # Clear all pane names
    unset pane_names
    declare -gA pane_names
    sync_pane_file
    save_pane_names
    
    tmux has-session -t "dev" 2>/dev/null
    if [ $? != 0 ]; then
        echo "Creating new session: dev"
        tmux new -s "dev"
    else
        echo "Attaching to existing session: dev"
        tmux attach-session -t "dev"
    fi
}

tclose() {
    local pane_index=$1

    # If no pane index was given
    if [[ -z "$pane_index" ]]; then
        tmux kill-pane
    else # If pane index was specified
        tmux kill-pane -t "%$(get_pane_id $pane_index)"
    fi
}

tcloseall() {
    tmux kill-pane -a
    echo "All panes in the current window killed."
    tclose # Close the last pane
}

alias tca="tcloseall"
alias rip="run_in_pane"
alias ripuf="run_in_pane_until_finished"
alias tc="tclose"

###############################################
# Start of LSR module #10                     #
# Injected LSR module: version_management.sh  #
# Number of lines: 88                         #
# Filesize: 2.55 KB                           #
###############################################
# Source the needed helper files
source ~/scripts/helpers.sh

BASHRC_PATH=~/.bashrc
BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
BASHRC_STARTER="# !! LSR LOADER START !!"
BASHRC_ENDERER="# !! LSR LOADER END !!"
SETTINGS_FILE=~/scripts/_settings.yml
HISTORY_FILE=~/scripts/local_data/version_history.yml

alias lstatus=lsr_status
alias linstall=lsr_install
alias lreinstall=lsr_reinstall
alias luninstall=lsr_uninstall

lsr_status() {
    # Variable to store installation status
    local bashrc_installed=false
    local local_data_installed=false

    # Check if the identifier exists in .bashrc
    if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        bashrc_installed=true
    fi

    # Check if there's a version history file and if it contains the current version
    if [ -f "$HISTORY_FILE" ]; then
        CURRENT_VERSION=$(yq e '.version_history[-1]' "$HISTORY_FILE" 2>/dev/null)
        if [ ! -z "$CURRENT_VERSION" ]; then
            local_data_installed=true
        fi
    fi

    # Check if both bashrc and version history are present
    if [ "$bashrc_installed" = true ] && [ "$local_data_installed" = true ]; then
        # Retrieve the installed version from _settings.yml
        NAME=$(yq e '.name' "$SETTINGS_FILE")
        MAJOR_VERSION=$(yq e '.version.major' "$SETTINGS_FILE")
        MINOR_VERSION=$(yq e '.version.minor' "$SETTINGS_FILE")
        FULL_VERSION="v$MAJOR_VERSION.$MINOR_VERSION"

        print_success "$NAME $FULL_VERSION is installed."
    else
        print_error "Lukes Script Repository is not installed."
    fi
}

lsr_install() {
    ~/scripts/_install.sh
    reload_bash
}

lsr_reinstall() {
    print_info "Uninstalling LSR"
    lsrsilence true
    lsr_uninstall
    lsrsilence false

    print_info "Recompiling LSR"
    lsrsilence true
    lsr_compile
    lsrsilence false

    print_info "Installing LSR"
    lsrsilence true
    lsr_install
    lsrsilence false
}

lsr_uninstall() {
    # 1. Remove the version history file if it exists
    if [[ -f "$HISTORY_FILE" ]]; then
        rm "$HISTORY_FILE"
        print_info "Deleted version history file"
    fi

    # 2. Check if the LSR loader section exists before attempting to remove it
    if grep -q "^$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        # Remove the LSR loader section from .bashrc
        sed -i "/^$BASHRC_STARTER/,/^$BASHRC_ENDERER/d" "$BASHRC_PATH"
        print_info "Removed LSR loader from $BASHRC_PATH"
    fi

    print_empty_line
    print_info "LSR has been reinstalled"
    print_info " - linstall to undo"
    print_info " - Open new session to confirm"
    reload_bash
}
################################
# Start of LSR module #11      #
# Injected LSR module: vim.sh  #
# Number of lines: 36          #
# Filesize: 1004 B             #
################################
# Function to setup vim-plug for Vim
setup_vim_plug() {
    # Define the directory and file
    local vim_autoload_dir="$HOME/.vim/autoload"
    local plug_file="$vim_autoload_dir/plug.vim"

    # Create the autoload directory if it doesn't exist
    if [ ! -d "$vim_autoload_dir" ]; then
        mkdir -p "$vim_autoload_dir"
        print_info "Created directory: $vim_autoload_dir"
    fi

    # Download plug.vim if it doesn't exist
    if [ ! -f "$plug_file" ]; then
        curl -fLo "$plug_file" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        print_info "Downloaded vim-plug to $plug_file"
    fi
}


# Setting settings of vim
write_to_vimrc() {
    local vimrc_file="$HOME/.vimrc"

    setup_vim_plug

    # Hardcoded Vim configuration
    local vimrc_text="
source ~/scripts/extra_config_files/LukesVimConfig.vim
"

    # Create or clear the .vimrc file and write the hardcoded text
    echo "$vimrc_text" > "$vimrc_file"
}

write_to_vimrc
#################################
# Start of LSR module #12       #
# Injected LSR module: work.sh  #
# Number of lines: 99           #
# Filesize: 4.11 KB             #
#################################
# Command for seeing what people have done what work in my local repositories

work() {
    # Default values
    local date="$(date --date='yesterday' +%Y-%m-%d)"
    local filter_user=""
    local original_pwd=$(pwd)
    local work_git_dir=~/projects

    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --date=*)
                date="${1#*=}"
                shift
                ;;
            --user=*)
                filter_user="${1#*=}"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Convert the specified date into the appropriate format
    date=$(date --date="$date" +%Y-%m-%d)

    echo -e "\n\033[34mSearching for commits on $date in all repositories under $work_git_dir...\033[0m"

    # Loop through all subdirectories (assuming they are Git repositories)
    for repo in "$work_git_dir"/*; do # Go through all of the projects
        if [ -d "$repo/.git" ]; then # If they are git repos
            # Change into the repository's directory, fetch all
            cd "$repo" || continue
            
            echo -e "\n\033[36m=== $(basename "$repo") ===\033[0m"
            
            git fetch --all >/dev/null 2>&1

            # Get the commit logs from the specified date with full date and time
            commits=$(git log --all --remotes --branches --since="$date 00:00" --until="$date 23:59" --pretty=format:"%H|%an|%ae|%s|%ad" --date=iso --reverse)

            # Flag to check if any relevant commits were found
            local found_commits=false

            # Only display if there are commits
            if [ -n "$commits" ]; then
                # Loop through each commit to print the associated original branch name
                while IFS='|' read -r commit_hash username email commit_message commit_date; do
                    # Check if the user matches the filter (if specified)
                    local nickname="${user_map[$username]}"
                    
                    # Convert both the filter and the username/nickname to lowercase for case-insensitive comparison
                    local lower_username="$(echo "$username" | tr '[:upper:]' '[:lower:]')"
                    local lower_nickname="$(echo "$nickname" | tr '[:upper:]' '[:lower:]')"
                    local lower_filter_user="$(echo "$filter_user" | tr '[:upper:]' '[:lower:]')"

                    # Use nickname if it's set; otherwise, use the username
                    if [[ -n "$filter_user" && "$lower_filter_user" != "$lower_nickname" && "$lower_username" != "$lower_filter_user" ]]; then
                        continue
                    fi
                    
                    # Mark that we found a commit
                    found_commits=true
                    
                    # Get the branches that contain the commit
                    branches=$(git branch --contains "$commit_hash" | grep -v 'remotes/')
                    
                    # Get the first original branch (if available)
                    original_branch=$(echo "$branches" | sed 's/^\* //; s/^ //; s/ *$//' | awk '{print $1}' | head -n 1)

                    # If original_branch is empty, set it to "unknown"
                    if [[ -z "$original_branch" ]]; then
                        original_branch="unknown"
                    fi

                    # Format the commit date into hours and minutes (HH:MM)
                    time=$(date -d "$commit_date" +%H:%M)

                    # Map username to custom name
                    username="${user_map[$username]:-$username}"

                    # Customize the output with colors
                    echo -e "\033[32m$username\033[0m @ \033[33m$time\033[0m -> \033[35m$original_branch\033[0m: $commit_message"
                done <<< "$commits"
            fi

            # Print *No changes* if no relevant commits were found
            if [ "$found_commits" = false ]; then
                echo -e "\033[31m*No changes*\033[0m"
            fi
        fi
    done

    # Return to the original working directory
    cd "$original_pwd"
}
##################################
# Start of LSR module #13        #
# Injected LSR module: other.sh  #
# Number of lines: 288           #
# Filesize: 9.48 KB              #
##################################
LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Update PS1 to include the Git branch if in a Git repo
get_project_branch_label() {
    local current_project=$(get_current_project_label)
    local current_branch=$(parse_git_branch)

    if [[ -n $current_project && -n $current_branch ]]; then
        echo -e " ($RED$current_project$RESET: $current_branch)"
    else
        if [[ -n $current_project ]]; then
            echo -e " ($RED$current_project$RESET)"
        fi

        if [[ -n $current_branch ]]; then
            echo -e " ($current_branch)"
        fi
    fi
}

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]$(get_project_branch_label)\$ '

get_dir_part() {
    current_project=$(cproj)
    if [[ -n $current_project ]]; then
        echo " 🔧 $current_project "
    else
        current_dir=$(pwd | sed "s|^$HOME|~|")
        echo " 📝 $current_dir "
    fi
}

get_git_part() {
    local current_branch=$(parse_git_branch)

    if [[ -n $current_branch ]]; then
        echo -e " 🔗 $current_branch "
    else
        echo ""
    fi
}

set_powerline_ps1() {
    local isRoot=0  # Default to not root
    if [[ ${EUID} -eq 0 ]]; then
        isRoot=1  # Set to 1 if running as root
    fi

    PS1=''

    local user_part
    local dir_part
    local git_part

    local black="0;0;0"
    local white="255;255;255"
    local red="255;0;0"
    local green="42;135;57"
    local blue="0;135;175"
    local yellow="179;127;55"

    # Define colors
    local blue_bg="\[\033[48;2;${blue}m\]"   # Blue Background
    local red_bg="\[\033[48;2;${red}m\]"     # Red Background
    local yellow_bg="\[\033[48;2;${yellow}m\]" # Darker Yellow Background
    local green_bg="\[\033[48;2;${green}m\]"    # Green Background
    local black_bg="\[\033[48;2;${black}m\]"    # Black Background

    local yellow_fg="\[\033[38;2;${yellow}m\]" # White Text
    local green_fg="\[\033[38;2;${green}m\]"       # Green Text
    local red_fg="\[\033[38;2;${red}m\]"       # Red Text
    local blue_fg="\[\033[38;2;${blue}m\]"       # Red Text
    local white_fg="\[\033[38;2;${white}m\]" # White Text
    local black_fg="\[\033[38;2;${black}m\]"       # Black Text

    if [[ $isRoot ]]; then
        user_part="${blue_bg}${white_fg} \u@\h ${blue_fg}${yellow_bg}"  # Blue arrow with yellow background
    else
        user_part="${red_bg}${white_fg} \u@\h ${red_fg}${yellow_bg}"  # Red arrow with yellow background
    fi

    # Directory part with darker yellow background and black text
    dir_part="${white_fg}${yellow_bg}\$(get_dir_part)${green_bg}${yellow_fg}"  # Yellow arrow with green background
    dir_ending_part="${white_fg}${yellow_bg}\$(get_dir_part)${black_bg}${yellow_fg}"

    # Git part with green background and white text
    git_part="${white_fg}${green_bg}\$(get_git_part)${green_fg}${black_bg}"  # Green arrow with blue background

    if [[ -z $(get_git_part) ]]; then
        PS1="${user_part}${dir_ending_part}\[\033[00m\] "
    else
        PS1="${user_part}${dir_part}${git_part}\[\033[00m\] "
    fi
}

set_powerline_ps1
PROMPT_COMMAND=set_powerline_ps1

lsrdebug() {
    local SETTINGS_FILE=~/scripts/_settings.yml
    local current_value=$(yq e '.debug' "$SETTINGS_FILE")

    if [[ -n "$1" ]]; then
        # If an argument is passed, set the value based on it
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".debug = $1" "$SETTINGS_FILE"
            print_info "Debug mode set to $1."
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
        # No argument passed, toggle the current value
        if [[ "$current_value" == "true" ]]; then
            yq e -i '.debug = false' "$SETTINGS_FILE"
            print_info "Debug mode disabled."
        else
            yq e -i '.debug = true' "$SETTINGS_FILE"
            print_info "Debug mode enabled."
        fi
    fi
}

lsrsilence() {
    local SETTINGS_FILE=~/scripts/_settings.yml
    local current_value=$(yq e '.silent' "$SETTINGS_FILE")

    if [[ -n "$1" ]]; then
        # If an argument is passed, set the value based on it
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".silent = $1" "$SETTINGS_FILE"
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
        # No argument passed, toggle the current value
        if [[ "$current_value" == "true" ]]; then
            yq e -i '.silent = false' "$SETTINGS_FILE"
        else
            yq e -i '.silent = true' "$SETTINGS_FILE"
        fi
    fi
}

now() {
    local local_settings_file="$HOME/scripts/local_data/local_settings.yml"
    local local_settings_dir="$(dirname "$local_settings_file")"
    local api_key
    local lat
    local lon
    local unconfigured=false

    # Ensure the local_settings directory exists
    mkdir -p "$local_settings_dir"

    # Create an empty local_settings.yml if it doesn't exist
    if [[ ! -f "$local_settings_file" ]]; then
        touch "$local_settings_file"
    fi

    # Function to retrieve weather settings from YAML
    get_weather_settings() {
        # Use yq to extract values from the YAML file
        api_key=$(yq e '.weatherapi.api_key // ""' "$local_settings_file")
        lat=$(yq e '.weatherapi.lat // ""' "$local_settings_file")
        lon=$(yq e '.weatherapi.lon // ""' "$local_settings_file")
        
        # Check if the weatherapi section exists, if not create it
        if [[ -z "$api_key" ]]; then
            yq e -i '.weatherapi.api_key = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.api_key' "$local_settings_file")
            unconfigured=true
        fi

        if [[ -z "$lat" ]]; then
            yq e -i '.weatherapi.lat = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.lat' "$local_settings_file")
            unconfigured=true
        fi

        if [[ -z "$lon" ]]; then
            yq e -i '.weatherapi.lon = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.lon' "$local_settings_file")
            unconfigured=true
        fi

        # Trim any whitespace or quotes from the extracted values
        api_key=$(echo "$api_key" | xargs)
        lat=$(echo "$lat" | xargs)
        lon=$(echo "$lon" | xargs)
    }

    # Get current time in "mm:hh dd/mm/yyyy" format
    local current_time=$(date +"%H:%M %d/%m/%Y")

    # Fetch weather data using the API settings
    get_weather_settings

    if [[ "$unconfigured" == "true" ]]; then
        print_error "Weather API is not configured in settings_data. Configure it with https://openweathermap.org/api\n"
        return 1
    fi
    
    # Call the weather API (OpenWeatherMap in this case)
    local weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$api_key&units=metric")

    # Check if the API returned a valid result
    if [[ -z "$weather_data" ]] || [[ "$(echo "$weather_data" | jq '.cod')" != "200" ]]; then
        print_error "Unable to fetch weather data\n"
        return 1
    fi

    # Parse the weather data using `jq`
    local temp_now=$(echo "$weather_data" | jq '.main.temp')
    local temp_min=$(echo "$weather_data" | jq '.main.temp_min')
    local temp_max=$(echo "$weather_data" | jq '.main.temp_max')
    local humidity=$(echo "$weather_data" | jq '.main.humidity')
    local wind_speed=$(echo "$weather_data" | jq '.wind.speed')
    local weather_condition=$(echo "$weather_data" | jq -r '.weather[0].description')
    local city=$(echo "$weather_data" | jq -r '.name')

    # Define ANSI color codes
    local bold="\033[1m"
    local green="\033[32m"
    local blue="\033[34m"
    local cyan="\033[36m"
    local reset="\033[0m"
    local red="\033[0;31m"
    local yellow='\033[0;33m'

    # Print formatted and colored output
    color_value() {
        local value="$1"
        local low_threshold="$2"
        local mid_threshold="$3"
        local high_threshold="$4"
        local colored_str

        # Use bc for comparisons
        if (( $(echo "$value < $low_threshold" | bc -l) )); then
            colored_str="${blue}${value}°C${reset}"
        elif (( $(echo "$value >= $low_threshold" | bc -l) && $(echo "$value < $mid_threshold" | bc -l) )); then
            colored_str="${green}${value}°C${reset}"
        elif (( $(echo "$value >= $mid_threshold" | bc -l) && $(echo "$value < $high_threshold" | bc -l) )); then
            colored_str="${yellow}${value}°C${reset}"
        else
            colored_str="${red}${value}°C${reset}"
        fi
        echo "$colored_str"
    }
    
    local temp_now_str=$(color_value "$temp_now" 10 20 25)
    local temp_min_str=$(color_value "$temp_min" 10 20 25)
    local temp_max_str=$(color_value "$temp_max" 10 20 25)
    local wind_speed_str=$(color_value "$wind_speed" 2 5 10)

    echo -e "${bold}${green}Now in $city:${reset}"
    echo -e "${cyan}$current_time${reset}"
    echo -e "Temperature: ${temp_now_str}°C (${temp_min_str}°C - ${temp_max_str}°C)"
    echo -e "Condition: ${weather_condition} (${wind_speed_str} m/s)"
    print_empty_line
}

lhelp() {
    local lhelp_file="$HOME/scripts/lhelp.txt"
    
    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line == \#* ]]; then
            printf "$RED%s$RESET\n" "$line"
        else
            printf "%s\n" "$line"
        fi
        
    done < "$lhelp_file"

    print_empty_line
}

# Ensure tmux is running
if [ -z "$TMUX" ]; then
    tmux
fi
