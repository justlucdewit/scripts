alias lsrversion="lsrversion_main_command"

lsrversion_main_command() {
    composite_define_command "lsrversion"

    # Define subcommands
    composite_define_subcommand "current"
    composite_define_subcommand "list"
    composite_define_subcommand "use"
    composite_define_subcommand "download" "[ <version> ]"

    # Describe subcommands
    composite_define_subcommand_description "current" "Show the current version of LSR that is being used"
    composite_define_subcommand_description "list" "Lists all of the downloaded LSR versions"
    composite_define_subcommand_description "use" "Use a specific LSR version"
    composite_define_subcommand_description "download" "Downloads the given version of LSR into your scripts/versions folder"

    composite_handle_subcommand "$@"
}

lsrversion_download() {
    local version="$1"

    if [[ -f "$HOME/scripts/scripts/download.sh" ]]; then
        bash -c "$(cat "$HOME/scripts/scripts/download.sh")" -- "$version"
    else
        bash -c "$(curl -s "https://raw.githubusercontent.com/justlucdewit/scripts/main/scripts/download.sh")" -- "$version"
    fi
}

lsrversion_current() {
    local current_version="$(grep "source \"$HOME/scripts/versions/" "$HOME/.bashrc" | awk -F'/' '{print $(NF-1)}')"

    if [[ "$current_version" == "" ]]; then
        print_warn "LSR is not installed"
        return
    fi

    print_info "Current version: $current_version"
}

lsrversion_list() {
    # Directory containing the versions
    versions_dir="$HOME/scripts/versions"

    # Check if the directory exists
    echo "Available versions:"
    if [ -d "$versions_dir" ]; then
        for version in "$versions_dir"/*; do
            echo " - $(basename "$version")"
        done
    fi
}

lsrversion_use() {
    local type="$1"
    local version="$2"

    if [[ -f "$HOME/scripts/scripts/install.sh" ]]; then
        bash -c "$(cat "$HOME/scripts/scripts/install.sh")" -- "$type" "$version"
    else
        bash -c "$(curl -s "https://raw.githubusercontent.com/justlucdewit/scripts/main/scripts/install.sh")" -- "$type" "$version"
    fi
    
    return
}
