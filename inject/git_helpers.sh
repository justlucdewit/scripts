# Define a function to check if you're in a Git repo and show the current branch
parse_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -n $branch ]]; then
        echo " ($branch)"
    fi
}

# Display your current branch name and commit count:
git_info() {
    branch=$(git rev-parse --abbrev-ref HEAD)
    commits=$(git rev-list --count HEAD)
    echo "On branch: $branch, commits: $commits"
}