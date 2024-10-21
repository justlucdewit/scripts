reload_bash() {
    source ~/.bashrc
    print_success '~/.bashrc reloaded!'
}

backup() {
    local backup_location="$1-backup"
    cp $1 $backup_location -r
}

alias c='clear'
alias p='proj'
alias cf='cfind'
alias today='work --date=today'
alias yesterday='work --date=yesterday'
alias l="ls -la"
alias rb="reload_bash"
alias files="explorer.exe ."

alias joke='curl -H "Accept: text/plain" https://icanhazdadjoke.com/'