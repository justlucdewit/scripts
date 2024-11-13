local_settings_file="$HOME/scripts/local_data/local_settings.yml"
local_settings_dir="$(dirname "$local_settings_file")"

alias profile="profile_main_command"

# Composite command
profile_main_command() {
    reset_ifs

    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - profile current"
        echo "  - profile list"
        echo "  - profile load <identifier>"
        echo "  - profile save <identifier>"
        echo "  - profile edit <identifier>"  # TODO
        echo "  - profile rename <old identifier> <new identifier>"  # TODO
        echo "  - profile delete <identifier>"  # TODO
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list"; then
        profile_list $@
    elif is_in_list "$command" "current"; then
        profile_current $@
    elif is_in_list "$command" "load"; then
        profile_load $@
    elif is_in_list "$command" "save"; then
        profile_save $@
    elif is_in_list "$command" "delete"; then
        profile_delete $@
    else
        print_error "Command $command does not exist"
        profile_main_command # Re-run for help command
    fi
}

profile_delete() {
    local current_profile="$(profile current)"

    # Get the profile name
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile delete <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1

    if [[ "$current_profile" == "$profile" ]]; then
        print_error "Cant delete current profile"
        return 1
    fi

    # Make sure new profile exist
    if [[ ! -f "$local_settings_dir/local_settings.$profile.yml" ]]; then
        print_error "Profile '$profile' doesnt exist"
    fi

    rm "$local_settings_dir/local_settings.$profile.yml"
}

profile_load() {
    # Get the profile name
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile load <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1

    # Make sure new profile exist
    if [[ ! -f "$local_settings_dir/local_settings.$profile.yml" ]]; then
        print_error "Profile '$profile' doesnt exist"
    fi

    # Load it
    cp "$local_settings_dir/local_settings.$profile.yml" "$local_settings_dir/local_settings.yml"
    print_success "Loaded profile local_settings.$profile.yml"
}

profile_save() {
    # Get the profile name
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile save <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1
    local current_profile="$(profile_current)"

    # Set current profile name
    lsset profile $profile &> /dev/null

    # If new profile already exists and is different from current profile,
    # Dont allow, since this will overwrite an existing profile
    if [[ -f "$local_settings_dir/local_settings.$profile.yml" && $profile != $current_profile ]]; then
        print_error "Aborting since this will overwrite existing profile '$profile'"
        return 1
    fi

    # Save it
    cp "$local_settings_dir/local_settings.yml" "$local_settings_dir/local_settings.$profile.yml"
    print_success "Saved current profile to local_settings.$profile.yml"
}

profile_list() {
    echo "Profiles: "
    for file in $local_settings_dir/local_settings*.yml; do
        if [ -f "$file" ]; then
            local file_name="$(basename "$file")"
            local profile_name="$(echo "$file_name" | sed 's/^local_settings.\(.*\).yml$/\1/')"
            
            if [[ "$profile_name" == "local_settings.yml" ]]; then
                continue
            fi
            
            echo "   - $profile_name"
        fi
    done
}

profile_current() {
    local profile="$(localsettings_get .profile)"

    if [[ "$profile" == "null" ]]; then
        profile="default"
        lsset profile "$profile" &> /dev/null
    fi

    echo "$profile"
}