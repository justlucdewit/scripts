alias branches="git_branches_main_command"

# Composite command
git_branches_main_command() {
    local filter=""
    local argument_count=$#
    local defined_commands=(
        "branches list"
        "branches go <branch-name>"
    )

    # composite_help_command "$filter" $argument_count "${defined_commands[@]}"

    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - branches list"
        echo "  - branches list feature"
        echo "  - branches go <branch-name>" # TODO
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list"; then
        local command=$1
        shift

        if [[ -z $command ]]; then
            git_branches_list $@
        else
            print_error "Command 'branches list $command' does not exist"
            git_branches_main_command # Re-run for help command
        fi
    elif is_in_list "$command" "go"; then
        git_branches_go $@
    else
        print_error "Command 'branches $command' does not exist"
        git_branches_main_command # Re-run for help command
    fi
}

git_branches_features_delete() {
    local featureName=$1

    if [[ -z $featureName ]]; then
        print_error "'branches feature delete' expects an argument for the feature-name\nUsage: branches feature delete <feature-name>"
        return 1
    fi

    local featureBranchName="feature/$featureName"

    if ! git_branch_exists $featureBranchName; then
        print_error "Branch $featureBranchName does not exist locally or remotely"
        return
    fi

    read_info "Deleting branch $featureBranchName, are you sure? (y/n): " confirm

    if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
        print_info "Branch deletion cancled..."
        return
    fi

    git checkout development &>/dev/null
    git branch --delete $featureBranchName &>/dev/null
    print_success "Deleted branch $featureBranchName"
}

git_branches_go() {
    local branchName=$1

    if [[ -z $branchName ]]; then
        print_error "'branches go' expects an argument for the branch-name\nUsage: branches feature go <branch-name>"
        return 1
    fi

    if ! git_branch_exists $branchName; then
        print_error "Branch $branchName does not exist locally or remotely"
        return
    fi

    git checkout $branchName &>/dev/null
    print_success "Switched to branch $branchName"
}

git_branches_list() {
    git branch --all --no-color
}