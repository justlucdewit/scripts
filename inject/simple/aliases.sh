# LSR Module that contains standalone aliases
alias c='clear'
alias l="ls -la"
alias rb="reload_bash"
alias today='work --date=today'
alias hosts='powershell.exe -Command "Start-Process \"C:\Program Files\Sublime Text\sublime_text.exe\" -ArgumentList \"C:\Windows\System32\Drivers\etc\hosts\" -Verb RunAs"'
alias refreshdns='powershell.exe -Command "ipconfig /flushdns"'
alias yesterday='work --date=yesterday'
alias subl='"/mnt/c/Program Files/Sublime Text/sublime_text.exe"'
alias lg="lazygit"
alias e=exp
alias eg="exp --go"
alias s=scripts
alias ss="select_scripts"
LSR_LOCAL_SETTINGS_FILE="$HOME/scripts/local_data/local_settings.yml"
LSR_LOCAL_SETTINGS_DIR="$(dirname "$local_settings_file")"