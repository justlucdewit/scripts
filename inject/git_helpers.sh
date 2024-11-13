alias gitusers="git_users_main_command"

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