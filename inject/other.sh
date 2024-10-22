LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Update PS1 to include the Git branch if in a Git repo
get_project_branch_label() {
    local current_project=$(get_current_project_label)
    local current_branch=$(parse_git_branch)

    if [[ -n $current_project && -n $current_branch ]]; then
        echo -e " ($RED$current_project$RESET: $current_branch)"
    else
        if [[ -n $current_project ]]; then
            echo " ($RED$current_project$RESET)"
        fi

        if [[ -n $current_branch ]]; then
            echo " ($current_branch)"
        fi
    fi
}

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]$(get_project_branch_label)\$ '
