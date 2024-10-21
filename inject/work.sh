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