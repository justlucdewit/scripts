# Define a function to check if you're in a Git repo and show the current branch
alias gitusers="git_users_main_command"

git_users_main_command() {
    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - gitusers list"
        echo "  - gitusers get <identifier>"
        echo "  - gitusers new <identifier> <fullname>"
        echo "  - gitusers del <identifier>"
        echo "  - gitusers alias <identifier> <alias>"
        echo "  - gitusers unlias <identifier> <alias>"
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list,all"; then
        list_git_users $@
    elif is_in_list "$command" "get"; then
        get_git_user $@
    elif is_in_list "$command" "new,create,add"; then
        new_git_user $@
    elif is_in_list "$command" "del,delete,rem,remove"; then
        delete_git_user $@
    elif is_in_list "$command" "add-alias,new-alias,create-alias,alias,"; then
        set_git_user_alias $@
    elif is_in_list "$command" "del-alias,rem-alias,delete-alias,remove-alias,unalias"; then
        unset_git_user_alias $@
    else
        print_error "Command $command does not exist"
        git_users_main_command # Re-run for help command
    fi
}

set_git_user_alias() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local alias=$(prompt_if_not_exists "Alias" $2)

    localsettings_eval_with_save ".gitusers.\"$identifier\".aliases += [ \"$alias\" ]"

    print_success "Added alias '$alias' to gituser '$identifier'"

    localsettings_reformat
}

unset_git_user_alias() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local alias=$(prompt_if_not_exists "Alias" $2)

    localsettings_eval_with_save "del(.gitusers.\"$identifier\".aliases[] | select(. == \"$alias\"))"

    print_success "Deleted alias '$alias' to gituser '$identifier'"

    localsettings_reformat
}

get_git_user() {
    # Get the needed values
    local identifier=$(prompt_if_not_exists "Identifier" $1)
    
    localsettings_reformat

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    localsettings_eval ".gitusers.\"$identifier\""
}

list_git_users() {
    localsettings_reformat
    localsettings_get .gitusers
}

delete_git_user() {
    # Get the needed values
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if not exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exists"
        return 1
    fi

    localsettings_delete ".gitusers.\"$identifier\""
    print_success "Deleted gituser \"$identifier\""
}

new_git_user() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\\\"$identifier\\\"")
    if [[ ! "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier already exists"
        return 1
    fi

    local fullname=$(prompt_if_not_exists "Fullname" $2)

    # Set the values to the local settings
    localsettings_eval_with_save ".gitusers.\"$identifier\".fullname = \"$fullname\"" > /dev/null
    localsettings_eval_with_save ".gitusers.\"$identifier\".aliases = [ \"$fullname\" ]" > /dev/null
    localsettings_reformat
    print_success "Created gituser \"$identifier\""
}

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