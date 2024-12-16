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
alias gitlog='git log --pretty=format:"%C(green)%h %C(blue)%ad %C(red)%an%C(reset): %C(yellow)%s%C(reset)" --color --date=format:"%d/%m/%Y %H:%M"'
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
alias ss="select_scripts"
alias yesterday='work --date=yesterday'
alias today='work --date=today'
alias rb="lsr_reload"

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
LSR_IS_DEV=$(yq e ".dev" "$LSR_SETTING_FILE")

