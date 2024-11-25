# LSR Module that contains standalone aliases

reload_bash() {
    source ~/.bashrc
    print_success '~/.bashrc reloaded!'
}

backup() {
    local backup_location="$1-backup"
    cp $1 $backup_location -r
}

alias hosts='powershell.exe -Command "Start-Process \"C:\Program Files\Sublime Text\sublime_text.exe\" -ArgumentList \"C:\Windows\System32\Drivers\etc\hosts\" -Verb RunAs"'
alias refreshdns='powershell.exe -Command "ipconfig /flushdns"'
alias c='clear'
alias cf='cfind'
alias today='work --date=today'
alias yesterday='work --date=yesterday'
alias l="ls -la"
alias rb="reload_bash"
alias files="explorer.exe ."
alias subl='"/mnt/c/Program Files/Sublime Text/sublime_text.exe"'
