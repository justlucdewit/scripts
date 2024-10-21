# A command to quickly switch projects
proj() {
    # Check if the provided project exists in the map
    if [[ -n "${projects[$1]}" ]]; then
        cd "${projects[$1]}" || echo "Failed to navigate to ${projects[$1]}"
    else
        echo "Project not found. Available projects:"
        for key in "${!projects[@]}"; do
            echo " - $key"
        done
    fi
}