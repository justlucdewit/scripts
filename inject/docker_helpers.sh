# Define color codes
LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

alias dock="dock_main_command"

# Composite command
dock_main_command() {
    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - dock list"
        echo "  - dock start <index>"
        echo "  - dock stop <index>"
        echo "  - dock delete <index>"
        echo "  - dock start"
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list,all"; then
        dock_list $@
    elif is_in_list "$command" "start,up,go"; then
        dock_start_project $@
    elif is_in_list "$command" "stop,down,halt"; then
        dock_stop_project $@
    elif is_in_list "$command" "del,delete,rem,remove"; then
        dock_remove_project $@
    elif is_in_list "$command" "restart,start,boot,reboot"; then
        dock_restart $@
    else
        print_error "Command $command does not exist"
        dock_main_command # Re-run for help command
    fi
}

dock_list() {
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

dock_start_project() {
    if [ -z "$1" ]; then
        print_error "Usage: dock start <number>"
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
dock_stop_project() {
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
dock_remove_project() {
    if [ -z "$1" ]; then
        print_error "Usage: dock remove <number>"
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

dock_restart() {
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