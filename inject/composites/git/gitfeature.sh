alias feature="git_feature_main_command"

git_feature_main_command() {
    composite_define_command "feature"
    composite_define_subcommand "list"
    composite_define_subcommand "new"
    composite_define_subcommand "delete"
    composite_define_subcommand "go"
    composite_define_subcommand "update"

    composite_handle_subcommand $@
}

feature_list() {
    git branch --all | grep " feature/" --color=never
}

feature_new() {
    local featureName=$(prompt_if_not_exists "feature name" $1)
    local featureBranchName="feature/$featureName"
    print_info "Creating branch $featureBranchName..."

    git checkout develop &>/dev/null
    git branch $featureBranchName &>/dev/null
    git checkout $featureBranchName &>/dev/null

    print_success "Branch $featureBranchName was created succesfully"
}

feature_delete() {
    local featureName=$(prompt_if_not_exists "feature name" $1)
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

feature_go() {
    local featureName=$(prompt_if_not_exists "feature name" $1)
    local featureBranchName="feature/$featureName"

    if ! git_branch_exists $featureBranchName; then
        print_error "Branch $featureBranchName does not exist locally or remotely"
        return
    fi

    git checkout $featureBranchName &>/dev/null
    print_success "Switched to branch $featureBranchName"
}

feature_update() {
    local message=$(prompt_if_not_exists "commit message" $1)

    git add .
    git commit -m "$message"
    git push origin "$(parse_git_branch)"
}