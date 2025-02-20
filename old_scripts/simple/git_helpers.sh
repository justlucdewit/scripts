git_branch_exists() {
    branchName="$1"

    # Check if the branch exists locally
    local localBranches
    localBranches=$(git branch --list "$branchName")
    if [[ -n "$localBranches" ]]; then
        return 0  # Branch exists locally
    fi

    # Check if the branch exists remotely
    local remoteBranches
    remoteBranches=$(git branch --all | grep -w "remotes/origin/$branchName")
    if [[ -n "$remoteBranches" ]]; then
        return 0  # Branch exists remotely
    fi

    # If branch doesn't exist locally or remotely
    return 1  # Branch does not exist
}

find_git_user_by_alias() {
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        print_error "find_git_user_by_alias is LSR-FULL only"
        exit
    fi
    
    local alias=$1

    if [[ -z $alias ]]; then
        print_error "find_git_user_by_alias expects an argument for the alias to search"
        return 1
    fi

    localsettings_eval "( .gitusers | to_entries | map(select(.value.aliases[] == \"$alias\")) )[0] | { \"identifier\": .key, \"fullname\": .value.fullname, \"aliases\": .value.aliases } "
}

parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -n $branch ]]; then
        echo "$branch"
    fi
}

gitstats() {
    echo -e "Repository statistics:\n"

    declare -A alias_to_identifier
    declare -A commit_counts
    local total_commit_count=0

    # Preload alias-to-identifier mapping from the YAML file
    while IFS= read -r alias; do
        local gituser=$(find_git_user_by_alias "${alias:2}")
        local identifier=$(echo "$gituser" | yq e '.identifier' -)
        alias_to_identifier["${alias:2}"]="$identifier"
    done < <(lseval '.gitusers[].aliases')

    # Get the list of commit authors
    commits=$(git log --all --remotes --branches --pretty=format:"%an")

    # Process commit authors
    while IFS= read -r commit_author; do
        # Lookup the identifier from the preloaded associative array
        gituser_identifier=${alias_to_identifier["$commit_author"]}

        # If the alias isn't found, assign a default identifier
        if [[ -z "$gituser_identifier" ]]; then
            gituser_identifier="unknown"
        fi

        # Increment the count for the identifier
        ((commit_counts["$gituser_identifier"]++))
        ((total_commit_count++))
    done <<< "$commits"

    echo "Total commits: $total_commit_count"
    echo

    # Sort and print the commit counts in descending order
    for identifier in "${!commit_counts[@]}"; do
        echo "$identifier ${commit_counts[$identifier]}"
    done | sort -k2 -nr | while read -r identifier count; do
        echo "Commits by $identifier: $count"
    done
}
