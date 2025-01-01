alias accounts="accounts_main_command"

accounts_main_command() {
    composite_define_command "accounts"
    composite_define_subcommand "current"
    composite_define_subcommand "list"
    composite_define_subcommand "delete" "<account name>"
    composite_define_subcommand "create" "<account name> <password>"

    composite_handle_subcommand "$@"
}

accounts_current() {
    whoami
}

accounts_list() {
    # Capture output of the command that lists non-system users
    local users=$(awk -F: '$3 >= 1000 && $3 < 65534 && $7 !~ /nologin|false/ {print $1}' /etc/passwd)
    local current_user=$(accounts_main_command current)

    # Neatly print all of the users
    while IFS= read -r user; do
        if [[ "$user" == "$current_user" ]]; then
            echo -e " - $LSR_COLOR_GREEN$user$LSR_COLOR_RESET"
        else
            echo " - $user"
        fi
    done <<< "$users"
}

accounts_delete() {
    name="$1"
    local users=$(awk -F: '$3 >= 1000 && $3 < 65534 && $7 !~ /nologin|false/ {print $1}' /etc/passwd)
    local current_user=$(accounts_main_command current)

    if [[ -z "$name" ]]; then
        print_error "No account name provided"
        return
    fi

    if [[ "$name" == "$current_user" ]]; then
        print_error "Not allowed to delete current user '$current_user'"
        return
    fi

    # Loop over all of the users
    while IFS= read -r user; do
        
    done <<< "$users"

    # Handle case where no account was found
    print_error "Account '$name' does not exist"
}