alias wsl="wsl_main_command"

wsl_main_command() {
    composite_define_command "wsl"
    composite_define_subcommand "c"
    composite_define_subcommand "open"
    composite_define_subcommand "desktop"
    composite_define_subcommand "downloads"

    composite_handle_subcommand $@
}

wsl_desktop() {
    windows_username=$(powershell.exe -Command '[Environment]::UserName' | tr -d '\r')
    cd "/mnt/c/Users/$windows_username/Desktop"
}

wsl_downloads() {
    windows_username=$(powershell.exe -Command '[Environment]::UserName' | tr -d '\r')
    cd "/mnt/c/Users/$windows_username/Downloads"
}

wsl_open() {
    explorer.exe .
}

wsl_c() {
    cd "/mnt/c"
}