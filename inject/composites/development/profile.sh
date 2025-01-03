local_settings_file="$HOME/scripts/local_data/local_settings.yml"
local_settings_dir="$(dirname "$local_settings_file")"

alias profile="profile_main_command"

# Composite command
profile_main_command() {
    reset_ifs

    # Define subcommands
    composite_define_command "profile"
    composite_define_subcommand "list"
    composite_define_subcommand "current"
    composite_define_subcommand "load" "<profile>"
    composite_define_subcommand "save" "<profile>"
    composite_define_subcommand "edit" "<profile>"
    composite_define_subcommand "delete" "<profile>"

    # Describe subcommands
    composite_define_subcommand_description "list" "List all of the profiles available"
    composite_define_subcommand_description "current" "Shows the currently active profile"
    composite_define_subcommand_description "load" "Loads the given profile"
    composite_define_subcommand_description "save" "Saves the current profile to the given profile name"
    composite_define_subcommand_description "edit" "Edits the given profile in the editor"
    composite_define_subcommand_description "delete" "Deletes the given profile"

    composite_handle_subcommand $@
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

profile_select() {
    profile_output=$(profile_list)
    profile_list=$(echo "$profile_output" | grep '^ - ' | awk '{sub(/^ - /, ""); if (NR > 1) printf ","; printf "%s", $0} END {print ""}')
    
    local value=""
    selectable_list "Select a profile" value "$profile_list"
    profile load $value
}

profile_load() {
    # Get the profile name
    if [ "$#" -ne 1 ]; then
        profile_select
        return 0  # Return an error code
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

profile_edit() {
    # Get the profile name
    if [ "$#" -ne 1 ]; then
        echo "Usage: profile save <identifier>"
        return 1  # Return an error code
    fi
    local profile=$1
    echo "profile => $local_settings_dir/local_settings.$profile.yml"

    if [[ ! -f "$local_settings_dir/local_settings.$profile.yml" ]]; then
        print_error "Profile '$profile' does not exist"
        return 1
    fi

    vim "$local_settings_dir/local_settings.$profile.yml"
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
            
            echo " - $profile_name"
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