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
new_project() {
    local project_name="$1"
    local project_dir="$2"
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    if [[ -z "$project_name" ]]; then
        echo "Usage: nproject <project_name> [project_directory]"
        return 1
    fi
    if [[ -z "$project_dir" ]]; then
        project_dir="."  # Convert to lowercase and set a default directory
    fi
    project_dir=$(realpath -m "$project_dir" 2>/dev/null) || project_dir="$(cd "$project_dir" && pwd)"
    if [[ -f "$yaml_file" ]]; then
        if [[ $(yq eval ".projects | has(\"$project_name\")" "$yaml_file") == "true" ]]; then
            echo "Project '$project_name' already exists in local_settings."
        else
            yq eval -i ".projects.$project_name = {\"dir\": \"$project_dir\", \"url\": null}" "$yaml_file"
            echo "Added project '$project_name' to local_settings."
        fi
        localsettings_reformat
    else
        echo "YAML file not found: $yaml_file"
    fi
}
remove_project() {
    local project_name="$1"
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    if [[ -z "$project_name" ]]; then
        echo "Usage: premove <project_name>"
        return 1
    fi
    if [[ -f "$yaml_file" ]]; then
        if [[ $(yq eval ".projects | has(\"$project_name\")" "$yaml_file") == "true" ]]; then
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
    if [[ -n "$1" ]]; then
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
        list_projects "$show_dirs"  # Pass the option to list_projects
    fi
}
current_project() {
    local cwd
    cwd=$(pwd | xargs)  # Get the current working directory
    local project_list
    project_list=$(proj --dirs 2>/dev/null | sed '1d')  # Suppress errors and output
    while IFS= read -r line; do
        local project_name
        local project_path
        project_name=$(echo "$line" | awk -F ': ' '{print $1}' | sed 's/\x1B\[[0-9;]*m//g')
        project_path=$(echo "$line" | awk -F ': ' '{print $2}' | sed 's/\x1B\[[0-9;]*m//g')
        project_path=$(echo "$project_path" | xargs)
        if [[ "$cwd" == "$project_path" ]]; then
            echo "$project_name" | awk -F ' - ' '{print $2}'  # Return the project name if it matches
            return 0
        fi
    done <<< "$project_list"
    return 1
}
load_yaml_projects() {
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    declare -gA yaml_projects=()  # Temporary array to store YAML projects
    if [[ -f "$yaml_file" ]]; then
        
        
        while IFS="=" read -r key value; do
            
            key=$(echo "$key" | xargs)    # Trim whitespace
            value=$(echo "$value" | xargs) # Trim whitespace
            if [[ "$value" == "~"* ]]; then
                value="${HOME}${value:1}"  # Replace ~ with $HOME
            fi
            yaml_projects["$key"]="$value"
        done < <(lseval ".projects | to_entries | .[] | .key + \"=\" + .value.dir")
    fi
}
list_projects() {
    sync_projects  # Sync the combined projects array
    local current_dir=$(pwd)
    local green='\033[0;32m'
    local reset='\033[0m'
    echo "Available projects:"
    local show_dirs="$1"
    for key in "${!combined_projects[@]}"; do
        if [[ "${combined_projects[$key]}" == "$current_dir" ]]; then
            if [[ "$show_dirs" == true ]]; then
                echo -e "${green} - $key: ${combined_projects[$key]}${reset}"
            else
                echo -e "${green} - $key${reset}"  # Green highlight for the project name
            fi
        else
            if [[ "$show_dirs" == true ]]; then
                echo " - $key: ${combined_projects[$key]}"
            else
                echo " - $key"
            fi
        fi
    done
}
sync_projects() {
    load_yaml_projects
    combined_projects=()
    for key in "${!projects[@]}"; do
        combined_projects["$key"]="${projects[$key]}"
    done
    for key in "${!yaml_projects[@]}"; do
        combined_projects["$key"]="${yaml_projects[$key]}"
    done
}
source "$HOME/scripts/helpers.sh"
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
    "cfind"
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
            
            get_length() {
                echo "${#1}"
            }
            max_content_length=$(get_length "$module_index_line")
            for line in "$module_name_line" "$line_count_line" "$filesize_line"; do
                line_length=$(get_length "$line")
                if [[ $line_length -gt $max_content_length ]]; then
                    max_content_length=$line_length
                fi
            done
            max_line_length=$((max_content_length + 2)) # +2 for the hashtags on each side
            horizontal_line=$(printf "#%0.s" $(seq 1 $max_line_length))
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
    print_empty_line
    print_info "Generating minimized build file"
    local remove_comment_lines='^\s*#'  # Matches lines that are just comments
    local trim_whitespace='^\s*|\s*$'   # Matches leading and trailing whitespace on each line
    local remove_empty_lines='^$'       # Matches empty lines
    
    if [[ ! -f $minimized_build_file ]]; then
        touch "$minimized_build_file"
    fi
    cp "$build_file" "$minimized_build_file"
    sed -i "/$remove_comment_lines/d" "$minimized_build_file"
    sed -i "s/$trim_whitespace//g" "$minimized_build_file"
    sed -i "/$remove_empty_lines/d" "$minimized_build_file"
    print_info "Total final build.min.sh size: $(get_filesize "$minimized_build_file")"
    print_info "Total final build.min.sh lines: $(get_line_count "$minimized_build_file")"
    reload_bash
}
unset -v projects
declare -gA projects=(
    ["scripts"]="$HOME/scripts" # Add scripts as a hardcoded project
)
unset -v user_map
declare -gA user_map=(
    ["CK"]="Cem"
    ["luc.dewit"]="Luc"
    ["Luc de Wit"]="Luc"
    ["justlucdewit"]="Luc"
    ["Reinout Boelens"]="Reinout"
    ["Eli"]="Eli"
    ["Maurits van Mierlo"]="Maurits"
    ["Bram Gubbels"]="Bram"
    ["riyadbabouri"]="Riyad"
)
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
LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
docklist() {
    echo -e "${BLUE}Container Overview:${RESET}"
    
    declare -A projects
    declare -A project_status
    while IFS= read -r container; do
        container_id=$(echo "$container" | awk '{print $1}')
        container_name=$(echo "$container" | awk '{print $2}')
        project_name=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' "$container_id")
        status=$(docker inspect --format '{{.State.Status}}' "$container_id")
        if [[ -n "$project_name" ]]; then
            projects["$project_name"]+="$container_id:$container_name;"
            if [[ -z "${project_status[$project_name]}" ]]; then
                project_status["$project_name"]="$status"
            fi
        fi
    done < <(docker ps -aq)  # Read all container IDs
    longest_name=0
    for project in "${!projects[@]}"; do
        length=${#project}
        if (( length > longest_name )); then
            longest_name=$length
        fi
    done
    printf "${YELLOW}%-5s\t%-${longest_name}s\t%s\n${RESET}" "Index" "Project Name" "Status"  # Fixed-width headers
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
    mapfile -t project_names < <(docker ps -aq --filter "label=com.docker.compose.project" | xargs docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u)
    project_name="${project_names[$(( $1 - 1 ))]}"  # Convert to zero-based index
    if [ -z "$project_name" ]; then
        print_error "No project found at index $1."
        return 1
    fi
    container_ids=$(docker ps -aq --filter "label=com.docker.compose.project=$project_name")
    if [ -z "$container_ids" ]; then
        print_error "No stopped containers found for project '$project_name'."
        return 1
    fi
    print_success "Starting containers for project: $project_name"
    docker start $container_ids
}
dockstop() {
    if [ -z "$1" ]; then
        print_error "Usage: dockstop <number>"
        return 1
    fi
    project_name=$(docker ps --format '{{.ID}}' | xargs docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' | sort -u | sed -n "1p")
    print_debug $project_name
    if [ -z "$project_name" ]; then
        print_error "No project found at index $1."
        return 1
    fi
    container_ids=$(docker ps -q --filter "label=com.docker.compose.project=$project_name")
    if [ -z "$container_ids" ]; then
        print_error "No running containers found for project '$project_name'."
        return 1
    fi
    print_success "Stopping containers for project: $project_name"
    docker stop $container_ids
}
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
    if docker info >/dev/null 2>&1; then
        print_success "Docker is now running."
    else
        print_error "Failed to start Docker."
    fi
}
parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -n $branch ]]; then
        echo "$branch"
    fi
}
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
alias delete='git branch -d'
alias d="!f() { git branch -d $1 && git push origin --delete $1; }; f"
alias fresh="fresh_install_sail"
npmscripts() {
    local path="package.json"
    
    if [ ! -f "$path" ]; then
        echo "Error: $path not found."
        return 1
    fi
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
    local priority_order=("watch" "dev" "start")
    local scripts
    scripts=$(jq -r '.scripts | to_entries[] | .key' package.json)
    for script in "${priority_order[@]}"; do
        if echo "$scripts" | grep -q "^$script$"; then
            echo "$script"
            return 0
        fi
    done
    echo "No matching npm scripts found."
    return 1  # Exit with error if no matching scripts are found
}
create_start_layout() {
    local current_project="$(cproj)"
    if [[ $current_project == "" ]]; then
        print_error "Cannot start project because current dir is not a laravel project configured in proj"
        return 1
    fi
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
    if [[ -z $project ]]; then
        echo "Usage: switch <projectname>"
        return 0
    fi
    local failedSwitching=$(proj "$project" | grep -q "Project not found. Available projects:" && echo true || echo false)
    if [[ $failedSwitching == true ]]; then
        print_error "Cannot switch to project '$project' because it does not exist"
        proj
        return 1
    fi
    stop
    start $project
}
stop() {
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
    local project=$1
    local failedSwitching=$(proj "$project" | grep -q "Project not found. Available projects:" && echo true || echo false)
    if [[ $failedSwitching == true ]]; then
        print_error "Cannot start project '$project' because it does not exist"
        proj
        return 1
    fi
    if [[ -n "$project" ]]; then
        proj "$project"
    else # No project was given
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
    npm_script=$(get_first_npm_script)
    if grep -q "\"$npm_script\": \"vite" package.json; then
        print_info "starting npm with 'npm run $npm_script -- --no-open'"
        run_in_pane 1 "npm run $npm_script -- --no-open"
    else
        print_info "starting npm with 'npm run $npm_script'"
        run_in_pane 1 "npm run $npm_script"
    fi
    local projurl=$(get_project_url)
    if [[ "$projurl" == "null" ]]; then
        print_info "starting sail..."
        run_in_pane 0 sail up
    else
        run_in_pane 2 "(sleep 5; explorer.exe $projurl) &" 
        print_info "starting sail..."
        run_in_pane 0 sail up
    fi
    return 0
}
fresh_install_sail() {
    if [[ "$1" == "--remove-docker-image" ]]; then
        if [[ $(docker ps -aq -f "name=your_container_name") ]]; then
            ./vendor/bin/sail down --rmi all --volumes
            print_success "Docker containers, images, and volumes removed."
        else
            print_error "No Docker container found to remove."
        fi
    fi
    if [ -d "vendor" ]; then
        rm -rf vendor
        print_success "Removed vendor directory."
    else
        print_info "No vendor directory found."
    fi
    if [ -d "node_modules" ]; then
        rm -rf node_modules
        print_success "Removed node_modules directory."
    else
        print_info "No node_modules directory found."
    fi
    composer install
    print_success "PHP dependencies installed."
    npm install
    print_success "JavaScript dependencies installed."
    if [[ "$1" == "--remove-docker-image" ]]; then
        ./vendor/bin/sail create
        print_success "Docker containers created."
    else
        ./vendor/bin/sail build
        print_success "Docker containers built."
    fi
}
local_settings_file="$HOME/scripts/local_data/local_settings.yml"
local_settings_dir="$(dirname "$local_settings_file")"
alias lsget="localsettings_get"
alias lsset="localsettings_set"
alias lseval="localsettings_eval"
localsettings_ensureexists() {
    local field="$1"
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi
    local value=$(yq e "$field // \"\"" "$local_settings_file")
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
    while getopts "auh" opt; do
        case "$opt" in
            a) allow_create=true ;;
            u) unquoted=true ;;
            h) show_help; return 0 ;;
            \?) print_normal "Invalid option: -$OPTARG" >&2; return 1 ;;
            :) print_normal "Option -$OPTARG requires an argument." >&2; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))
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
    if [[ -z "$field" || -z "$value" ]]; then
        print_normal "Error: FIELD and VALUE are required." >&2
        return 1
    fi
    if [[ "$field" != .* ]]; then
        field=".$field"
    fi
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi
    if $allow_create; then
        localsettings_ensureexists "$field"
    fi
    print_normal "$unquoted"
    if [[ $unquoted == "true" ]]; then
        print_normal "YEEE"
        print_normal "yq e -i \"$field=$value\" \"$local_settings_file\""
        yq e -i "$field=$value" "$local_settings_file"
    else
        yq e -i "$field=\"$value\"" "$local_settings_file"
    fi
}
yq_validate_only_lookup() {
    local field="$1"
    if [[ "$field" == "." ]]; then
        return 0  # Valid case for root access
    fi
    if [[ ! "$field" =~ ^\.[a-zA-Z_-][a-zA-Z0-9_.-]*(\[[0-9]+\])?(\.[a-zA-Z_-][a-zA-Z0-9_.-]*(\[[0-9]+\])?)*$ ]]; then
        print_error "Invalid field format '${field}'. Only lookup notation is allowed (e.g., .projects or .projects.test-example).\n"
        return 1  # Exit with an error
    fi
    return 0
}
localsettings_reformat() {
    yq e -P '.' -i "$local_settings_file"
}
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
    if [[ ! "$pane_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Pane number must be a number."
        return 1
    fi
    local pane_id=$(tmux list-panes -F "#{pane_index} #{pane_id}" | awk -v num="$pane_number" '$1 == num {print $2}'  | tr -d '%')
    if [ -z "$pane_id" ]; then
        echo "No pane found with number: $pane_number"
        return 1
    fi
    echo "$pane_id"
}
get_pane_number() {
    if [ -z "$1" ]; then
        echo "Usage: get_pane_number <pane_id_without_percentage>"
        return 1
    fi
    local pane_id="$1"
    
    if [[ ! "$pane_id" =~ ^[0-9]+$ ]]; then
        echo "Error: Pane ID must be a number."
        return 1
    fi
    local pane_index=$(tmux list-panes -F "#{pane_id},#{pane_index}" | grep "%${pane_id}" | cut -d',' -f2)
    if [ -z "$pane_index" ]; then
        echo "No pane found with ID: %$pane_id"
        return 1
    fi
    echo "$pane_index"
}
debug_message() {
    if [[ "$DEBUG_CACHE_WRITING" = true ]]; then
        print_debug "$1"
    fi
}
declare -gA pane_names
set_stored_pane_name() {
    local key="$1"
    local value="$2"
    pane_names["$key"]="$value"
}
sync_pane_names() {
    debug_message "SYNCING PANE NAMES..."
    
    declare -A old_pane_names 
    for key in "${!pane_names[@]}"; do
        old_pane_names["$key"]="${pane_names[$key]}"
    done
    unset pane_names
    declare -gA pane_names
    load_pane_names
    sessions=$(tmux list-sessions -F '#S')  # Get all session names
    for session in $sessions; do
        current_windows=$(tmux list-windows -t "$session" -F '#I')  # Get window indices for each session
        for window in $current_windows; do
            panes=$(tmux list-panes -t "$session:$window" -F '#D')
            for pane in $panes; do
                pane_key="$session:$window:$pane"
                if [[ -z "pane_names[$pane_key]" ]]; then
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
    
    if [ ${#pane_names[@]} -eq 0 ]; then
        echo "No named panes found."
        return
    fi
    for key in "${!pane_names[@]}"; do
        echo "$key: ${pane_names[$key]}"
    done
}
load_pane_names() {
    debug_message "LOADING PANE NAMES..."
    if [[ ! -f "$PANE_NAME_FILE" ]]; then
        return
    fi
    unset pane_names
    declare -gA pane_names
    while IFS=':' read -r session window pane name; do
        if [[ -n "$session" && -n "$window" && -n "$pane" && -n "$name" ]]; then
            pane_names["$session:$window:$pane"]="$name"
        else
            echo "Skipping malformed line: '$session:$window:$pane:$name'"
        fi
    done < "$PANE_NAME_FILE"
}
save_pane_names() {
    debug_message "SAVING PANE NAMES..."
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
alias wr="tmux select-window -t +1" # Move a window right
alias wl="tmux select-window -t -1" # Move a window left
alias wn="tmux new-window" # New window
alias wk="tmux kill-window" # Close window
alias rw="rename_window" # Rename window
alias sr="tmux rename-session"
alias sl=""
alias sn="tmux new-session"
alias sc="tmux kill-session"
alias sw=""
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
        pane_name=$1
        current_pane=$(tmux display-message -p '#D' | tr -d '%')  # Get the current pane id
    elif [[ $# -eq 2 ]]; then
        current_pane=$(get_pane_id $1)
        echo "going for pane $target_pane"
        pane_name=$2
    else
        echo "Usage: rename_pane [<pane_number>] <new_name>"
        return 1
    fi
    current_session=$(tmux display -p '#S')
    current_window=$(tmux display -p '#I')
    pane_key="${current_session}:${current_window}:${current_pane}"
    old_name=${pane_names[$pane_key]:-"Unnamed Pane"}
    pane_names[$pane_key]="$pane_name"
    save_pane_names
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
    current_pane_id=$(tmux display -p '#D' | tr -d '%')  # Unique pane ID
    pane_key="${current_session}:${current_window}:${current_pane_id}"
    current_pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}
    echo -e "${ACTIVE_LIST_ITEM}Session $current_session: \e[1;34m$current_session\e[0m"
    echo -e "${INDENT}${ACTIVE_LIST_ITEM}\e[1;32mWindow $current_window: Window $current_window\e[0m"
    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $current_pane_id: $current_pane_name\e[0m"
}
tlist() {
    load_pane_names
    sync_pane_names
    active_session=$(tmux display-message -p '#S')
    active_window=$(tmux display-message -p '#I')
    active_pane=$(tmux display-message -p '#D' | tr -d '%')
    tmux list-sessions -F '#S' | nl -w1 -s': ' | while read session; do
        session_number=$(echo "$session" | cut -d':' -f1 | xargs)  # Get the session number
        session_name=$(echo "$session" | cut -d':' -f2 | xargs)    # Get the session name
        if [ "$session_name" == "$active_session" ]; then
            echo -e "${ACTIVE_LIST_ITEM}\e[1;34mSession $session_number: $session_name\e[0m"
        else
            echo -e "${INACTIVE_LIST_ITEM}\e[1;34mSession $session_number: $session_name\e[0m"
        fi
        tmux list-windows -t "$session_name" -F '#I: #W' | while read -r window; do
            window_number=$(echo "$window" | cut -d':' -f1 | xargs)  # Get the window number
            window_name=$(echo "$window" | cut -d':' -f2 | xargs)    # Get the window name
            if [ "$session_name" == "$active_session" ] && [ "$window_number" == "$active_window" ]; then
                echo -e "${INDENT}${ACTIVE_LIST_ITEM}\e[1;32mWindow $window_number: $window_name\e[0m"
            else
                echo -e "${INDENT}${INACTIVE_LIST_ITEM}\e[1;32mWindow $window_number: $window_name\e[0m"
            fi
            tmux list-panes -t "$session_name:$window_number" -F '#D: #T' | while read -r pane; do
                pane_id=$(echo "$pane" | cut -d':' -f1 | xargs | tr -d '%')  # Get the pane number
                pane_number=$(get_pane_number $pane_id)
                pane_key="${session_name}:${window_number}:${pane_id}"
                pane_name=${pane_names[$pane_key]:-"Unnamed Pane"}
                if [ "$session_name" == "$active_session" ] && [ "$window_number" == "$active_window" ] && [ "$pane_id" == "$active_pane" ]; then
                    echo -e "${INDENT}${INDENT}${ACTIVE_LIST_ITEM}\e[1;33mPane $pane_id($pane_number): $pane_name\e[0m"
                else
                    echo -e "${INDENT}${INDENT}${INACTIVE_LIST_ITEM}\e[1;33mPane $pane_id($pane_number): $pane_name\e[0m"
                fi
            done
        done    
    done
}
resize_up() {
    local size=  # Default to 5 if no argument is provided
    
}
run_in_pane() {
    load_pane_names
    local current_pane=$(tmux display-message -p '#D')
    
    local target_pane=$1
    shift
    
    local command="$*"
    tmux send-keys -t $target_pane "$command" C-m
}
run_in_pane_until_finished() {
    load_pane_names
    local target_pane=$1
    shift
    local command="$*"
    tmux send-keys -t $target_pane "$command" C-m
    while true; do
        local pane_output=$(tmux capture-pane -pt $target_pane -S - )
        if [[ $pane_output =~ \$$  ]]; then  # Example: match shell prompt ending with "$ "
            break
        fi
        sleep 1
    done
}
alias tcur="tmux display-message -p 'Current pane number: #D'"
t() {
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
    local bashrc_installed=false
    local local_data_installed=false
    if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        bashrc_installed=true
    fi
    if [ -f "$HISTORY_FILE" ]; then
        CURRENT_VERSION=$(yq e '.version_history[-1]' "$HISTORY_FILE" 2>/dev/null)
        if [ ! -z "$CURRENT_VERSION" ]; then
            local_data_installed=true
        fi
    fi
    if [ "$bashrc_installed" = true ] && [ "$local_data_installed" = true ]; then
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
    if [[ -f "$HISTORY_FILE" ]]; then
        rm "$HISTORY_FILE"
        print_info "Deleted version history file"
    fi
    if grep -q "^$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
        sed -i "/^$BASHRC_STARTER/,/^$BASHRC_ENDERER/d" "$BASHRC_PATH"
        print_info "Removed LSR loader from $BASHRC_PATH"
    fi
    print_empty_line
    print_info "LSR has been reinstalled"
    print_info " - linstall to undo"
    print_info " - Open new session to confirm"
    reload_bash
}
setup_vim_plug() {
    local vim_autoload_dir="$HOME/.vim/autoload"
    local plug_file="$vim_autoload_dir/plug.vim"
    if [ ! -d "$vim_autoload_dir" ]; then
        mkdir -p "$vim_autoload_dir"
        print_info "Created directory: $vim_autoload_dir"
    fi
    if [ ! -f "$plug_file" ]; then
        curl -fLo "$plug_file" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        print_info "Downloaded vim-plug to $plug_file"
    fi
}
write_to_vimrc() {
    local vimrc_file="$HOME/.vimrc"
    setup_vim_plug
    local vimrc_text="
source ~/scripts/extra_config_files/LukesVimConfig.vim
"
    echo "$vimrc_text" > "$vimrc_file"
}
write_to_vimrc
work() {
    local date="$(date --date='yesterday' +%Y-%m-%d)"
    local filter_user=""
    local original_pwd=$(pwd)
    local work_git_dir=~/projects
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
    date=$(date --date="$date" +%Y-%m-%d)
    echo -e "\n\033[34mSearching for commits on $date in all repositories under $work_git_dir...\033[0m"
    for repo in "$work_git_dir"/*; do # Go through all of the projects
        if [ -d "$repo/.git" ]; then # If they are git repos
            cd "$repo" || continue
            
            echo -e "\n\033[36m=== $(basename "$repo") ===\033[0m"
            
            git fetch --all >/dev/null 2>&1
            commits=$(git log --all --remotes --branches --since="$date 00:00" --until="$date 23:59" --pretty=format:"%H|%an|%ae|%s|%ad" --date=iso --reverse)
            local found_commits=false
            if [ -n "$commits" ]; then
                while IFS='|' read -r commit_hash username email commit_message commit_date; do
                    local nickname="${user_map[$username]}"
                    
                    local lower_username="$(echo "$username" | tr '[:upper:]' '[:lower:]')"
                    local lower_nickname="$(echo "$nickname" | tr '[:upper:]' '[:lower:]')"
                    local lower_filter_user="$(echo "$filter_user" | tr '[:upper:]' '[:lower:]')"
                    if [[ -n "$filter_user" && "$lower_filter_user" != "$lower_nickname" && "$lower_username" != "$lower_filter_user" ]]; then
                        continue
                    fi
                    
                    found_commits=true
                    
                    branches=$(git branch --contains "$commit_hash" | grep -v 'remotes/')
                    
                    original_branch=$(echo "$branches" | sed 's/^\* //; s/^ //; s/ *$//' | awk '{print $1}' | head -n 1)
                    if [[ -z "$original_branch" ]]; then
                        original_branch="unknown"
                    fi
                    time=$(date -d "$commit_date" +%H:%M)
                    username="${user_map[$username]:-$username}"
                    echo -e "\033[32m$username\033[0m @ \033[33m$time\033[0m -> \033[35m$original_branch\033[0m: $commit_message"
                done <<< "$commits"
            fi
            if [ "$found_commits" = false ]; then
                echo -e "\033[31m*No changes*\033[0m"
            fi
        fi
    done
    cd "$original_pwd"
}
LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'
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
    dir_part="${white_fg}${yellow_bg}\$(get_dir_part)${green_bg}${yellow_fg}"  # Yellow arrow with green background
    dir_ending_part="${white_fg}${yellow_bg}\$(get_dir_part)${black_bg}${yellow_fg}"
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
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".debug = $1" "$SETTINGS_FILE"
            print_info "Debug mode set to $1."
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
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
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".silent = $1" "$SETTINGS_FILE"
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
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
    mkdir -p "$local_settings_dir"
    if [[ ! -f "$local_settings_file" ]]; then
        touch "$local_settings_file"
    fi
    get_weather_settings() {
        api_key=$(yq e '.weatherapi.api_key // ""' "$local_settings_file")
        lat=$(yq e '.weatherapi.lat // ""' "$local_settings_file")
        lon=$(yq e '.weatherapi.lon // ""' "$local_settings_file")
        
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
        api_key=$(echo "$api_key" | xargs)
        lat=$(echo "$lat" | xargs)
        lon=$(echo "$lon" | xargs)
    }
    local current_time=$(date +"%H:%M %d/%m/%Y")
    get_weather_settings
    if [[ "$unconfigured" == "true" ]]; then
        print_error "Weather API is not configured in settings_data. Configure it with https://openweathermap.org/api\n"
        return 1
    fi
    
    local weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$api_key&units=metric")
    if [[ -z "$weather_data" ]] || [[ "$(echo "$weather_data" | jq '.cod')" != "200" ]]; then
        print_error "Unable to fetch weather data\n"
        return 1
    fi
    local temp_now=$(echo "$weather_data" | jq '.main.temp')
    local temp_min=$(echo "$weather_data" | jq '.main.temp_min')
    local temp_max=$(echo "$weather_data" | jq '.main.temp_max')
    local humidity=$(echo "$weather_data" | jq '.main.humidity')
    local wind_speed=$(echo "$weather_data" | jq '.wind.speed')
    local weather_condition=$(echo "$weather_data" | jq -r '.weather[0].description')
    local city=$(echo "$weather_data" | jq -r '.name')
    local bold="\033[1m"
    local green="\033[32m"
    local blue="\033[34m"
    local cyan="\033[36m"
    local reset="\033[0m"
    local red="\033[0;31m"
    local yellow='\033[0;33m'
    color_value() {
        local value="$1"
        local low_threshold="$2"
        local mid_threshold="$3"
        local high_threshold="$4"
        local colored_str
        if (( $(echo "$value < $low_threshold" | bc -l) )); then
            colored_str="${blue}${value}${reset}"
        elif (( $(echo "$value >= $low_threshold" | bc -l) && $(echo "$value < $mid_threshold" | bc -l) )); then
            colored_str="${green}${value}${reset}"
        elif (( $(echo "$value >= $mid_threshold" | bc -l) && $(echo "$value < $high_threshold" | bc -l) )); then
            colored_str="${yellow}${value}${reset}"
        else
            colored_str="${red}${value}${reset}"
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
if [ -z "$TMUX" ]; then
    tmux
fi
banned_patterns=(
    "*.exe"
    "*/node_modules/*"
    "*/vendor/*"
    "*.lock"
    "*/.git/*"
    "*.log"
    "*/storage/framework/views/*"
    "*/public/*"
    "*/package-lock.json"
)
RED='\033[0;31m'
RESET='\033[0m'
is_banned() {
  local file="$1"
  for pattern in "${banned_patterns[@]}"; do
    if [[ "$file" == $pattern ]]; then
      return 0 # File matches a banned pattern
    fi
  done
  return 1 # File does not match any banned pattern
}
cfind() {
    local query=$1
    if [[ -z $query ]]; then
        echo "Usage: cfind <query string>"
        return 1
    fi
    escaped_query=$(echo "$query" | sed 's/[.*+?[^$()|{}]/\\&/g')
    find . -type f | while read -r filepath; do
        if ! is_banned "$filepath"; then
            local filename=$(basename "$filepath")
            
            awk -v pattern="$escaped_query" -v fname="$filepath" '
                {
                    gsub(/^[ \t]+/, "");
                    if ($0 ~ pattern) {
                        printf "\033[0;31m%s:%d:%d\033[0m: %s\n", fname, NR, index($0, pattern), $0
                    }
                }
            ' "$filepath"
        fi
    done
}
