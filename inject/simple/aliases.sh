# Original executables for overwrite
LSR_ORIGINAL_LS=$(which ls)

# Bash Colors
LSR_COLOR_RED='\033[0;31m'
LSR_COLOR_GREEN='\033[0;32m'
LSR_COLOR_YELLOW='\033[0;33m'
LSR_COLOR_BLUE='\033[0;34m'
LSR_COLOR_RESET='\033[0m'

LSR_STYLE_UNDERLINE='\e[4m'
LSR_STYLE_ITALIC='\e[3m'
LSR_STYLE_DIM='\e[2m'
LSR_STYLE_BOLD='\e[1m'
LSR_STYlE_RESET='\e[0m'

alias true=0
alias false=1

# Aliases for standard bash commands
alias c='clear'
alias l="ls -la"
alias q="exit"

# Aliases for 3rd party software
alias lg="lazygit"

# Aliases for WSL-only stuff
alias hosts='powershell.exe -Command "Start-Process \"C:\Program Files\Sublime Text\sublime_text.exe\" -ArgumentList \"C:\Windows\System32\Drivers\etc\hosts\" -Verb RunAs"'
alias refreshdns='powershell.exe -Command "ipconfig /flushdns"'
alias subl='"/mnt/c/Program Files/Sublime Text/sublime_text.exe"'

# Aliases for git commands
alias gl="gitlog"
gitlog() {
    local n="$1"

    if [[ -z "$n" ]]; then
        n="5"
    fi

    # If current dir is not a project
    local projectLabel=$(project current)
    if [ -z "$projectLabel" ]; then
        print_error "Current directory is not a project"
        return
    fi

    echo -e "\033[36m=== $projectLabel ===\033[0m"

    commits=$(git log -n$n --remotes --branches --pretty=format:"%H|%an|%ae|%s|%ad" --date=iso)

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
            date=$(date -d "$commit_date" +%d/%M/%y)

            # Map username to custom name
            if [[ $gituser_identifier != "null" ]]; then
                username=$gituser_identifier
            fi

            # Customize the output with colors
            echo -e "\033[33m$date $time\033[0m \033[32m$username\033[0m\033[0m: $commit_message"
        done <<< "$commits"
    fi
}


alias gs='git status'
alias gco='git checkout'
alias gbr='git branch --all'
alias gc='git commit'
alias gs='git stash'
alias lcomp="lsr compile"

# Aliases for LSR commands
alias p="project go"
alias sp="project select"
alias e=exp
alias eg="exp --go"
alias s=scripts
alias ss="scripts select"
alias yesterday='work --date=yesterday'
alias today='work --date=today'

alias lsget="localsettings_get"
alias lsset="localsettings_set"
alias lseval="localsettings_eval"
alias lsdel="localsettings_delete"
alias lssort="localsettings_sort"
alias lsformat="localsettings_reformat"

alias lsr_current_user="$(whoami)"
alias lsr_current_host="$(hostname)"

LSR_LOCAL_SETTINGS_FILE="$HOME/scripts/local_data/local_settings.yml"
LSR_LOCAL_SETTINGS_DIR="$(dirname "$local_settings_file")"

LSR_DAY="$(date +%d)"
LSR_MONTH="$(date +%m)"
LSR_YEAR="$(date +%Y)"

LSR_NOTES_DIR="$HOME/notes"
LSR_SETTING_FILE=~/scripts/_settings.yml
LSR_NOTES_TODAY_FILE="$LSR_NOTES_DIR/journal/$LSR_YEAR-$LSR_MONTH/$LSR_YEAR-$LSR_MONTH-$LSR_DAY.md"

if [[ "$LSR_TYPE" == "LSR-FULL" ]]; then
    LSR_IS_DEV=$(yq e ".dev" "$LSR_SETTING_FILE")
fi

