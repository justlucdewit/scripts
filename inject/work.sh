# Command for seeing what people have done what work in my local repositories
work() {
    # Default values
    local date="$(date --date='yesterday' +%Y-%m-%d)"
    local filter_user=""
    local filter_project=""
    local original_pwd=$(pwd)

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
            --project=*)
                filter_project="${1#*=}"
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

    echo -e "\n\033[34mSearching for commits on $date in all projects"

    # Loop through all subdirectories (assuming they are Git repositories)
    for repo in $(localsettings_eval ".projects[] | .dir"); do # Go through all of the projects
        if [ -d "$repo/.git" ]; then # If they are git repos
            # Change into the repository's directory, fetch all
            cd "$repo" || continue
            
            local projectlabel=$(localsettings_eval "(.projects | to_entries | map(select(.value.dir == \"$repo\")))[0].key")

            if [[ -n "$filter_project" && "$filter_project" != "$projectlabel" ]]; then
                continue;
            fi

            echo -e "\n\033[36m=== $projectlabel ===\033[0m"
            
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
                    local gituser=$(find_git_user_by_alias "$username")
                    local gituser_identifier=$(echo "$gituser" | yq e '.identifier' -)
                    
                    # Convert both the filter and the username/identifier to lowercase for case-insensitive comparison
                    local lower_username="$(echo "$username" | tr '[:upper:]' '[:lower:]')"
                    local lower_identifier="$(echo "$gituser_identifier" | tr '[:upper:]' '[:lower:]')"
                    local lower_filter_user="$(echo "$filter_user" | tr '[:upper:]' '[:lower:]')"

                    # Use identifier if it's set; otherwise, use the username
                    if [[ -n "$filter_user" && "$lower_filter_user" != "$lower_identifier" && "$lower_username" != "$lower_filter_user" ]]; then
                        continue
                    fi
                    
                    # Mark that we found a commit
                    found_commits=true
                    
                    # Format the commit date into hours and minutes (HH:MM)
                    time=$(date -d "$commit_date" +%H:%M)

                    # Map username to custom name
                    if [[ $gituser_identifier != "null" ]]; then
                        username=$gituser_identifier
                    fi

                    # Customize the output with colors
                    echo -e "\033[32m$username\033[0m@\033[33m$time\033[0m\033[0m: $commit_message"
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