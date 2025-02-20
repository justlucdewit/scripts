alias gitusers="git_users_main_command"

# Composite command
git_users_main_command() {
    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - gitusers list"
        echo "  - gitusers get <identifier>"
        echo "  - gitusers new <identifier> <fullname>"
        echo "  - gitusers del <identifier>"
        echo "  - gitusers alias <identifier> <alias>"
        echo "  - gitusers unlias <identifier> <alias>"
        echo "  - gitusers set-initials <identifier> <initials>"
        echo "  - gitusers set-email <identifier> <initials>"
        echo "  - gitusers set-phone <identifier> <initials>"
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "list,all"; then
        git_users_list $@
    elif is_in_list "$command" "get"; then
        git_users_get $@
    elif is_in_list "$command" "new,create,add"; then
        git_users_new $@
    elif is_in_list "$command" "del,delete,rem,remove"; then
        git_users_delete $@
    elif is_in_list "$command" "add-alias,new-alias,create-alias,alias,"; then
        git_users_set_alias $@
    elif is_in_list "$command" "del-alias,rem-alias,delete-alias,remove-alias,unalias"; then
        git_users_unset_alias $@
    elif is_in_list "$command" "set-initials"; then
        git_users_set_initials $@
    elif is_in_list "$command" "set-email"; then
        git_users_set_email $@
    elif is_in_list "$command" "set-phone"; then
        git_users_set_phone $@
    else
        print_error "Command $command does not exist"
        git_users_main_command # Re-run for help command
    fi
}

git_users_list() {
    eval "flags=($(composite_help_get_flags "$@"))"

    local INCLUDE_IDENTIFIER=true
    local INCLUDE_FULLNAME=true
    local INCLUDE_ALIASES=false
    local INCLUDE_INITIALS=false
    local INCLUDE_PHONE=false
    local INCLUDE_EMAIL=false
    
    if composite_help_contains_flag aliases "${flags[@]}"; then
        INCLUDE_ALIASES=true
    fi
    if composite_help_contains_flag initials "${flags[@]}"; then
        INCLUDE_INITIALS=true
    fi
    if composite_help_contains_flag phone "${flags[@]}"; then
        INCLUDE_PHONE=true
    fi
    if composite_help_contains_flag email "${flags[@]}"; then
        INCLUDE_EMAIL=true
    fi
    
    lsrlist create headers

    if [[ $INCLUDE_IDENTIFIER == true ]]; then
        lsrlist append headers "Identifier"
    fi
    if [[ $INCLUDE_FULLNAME == true ]]; then
        lsrlist append headers "Full name"
    fi
    if [[ $INCLUDE_ALIASES == true ]]; then
        lsrlist append headers "Aliases"
    fi
    if [[ $INCLUDE_INITIALS == true ]]; then
        lsrlist append headers "Initials"
    fi
    if [[ $INCLUDE_PHONE == true ]]; then
        lsrlist append headers "Phone"
    fi
    if [[ $INCLUDE_EMAIL == true ]]; then
        lsrlist append headers "Email"
    fi

    users=$(localsettings_get .gitusers)
    rows=()

    index=0
    while IFS= read -r user; do
        lsrlist create newRow

        if [[ $INCLUDE_IDENTIFIER == true ]]; then
            lsrlist append newRow "$user"
        fi
        if [[ $INCLUDE_FULLNAME == true ]]; then
            local fullname="$(localsettings_get .gitusers.$user.fullname)"
            lsrlist append newRow "$fullname"
        fi
        if [[ $INCLUDE_ALIASES == true ]]; then
            local aliases="$(localsettings_eval ".gitusers.$user.aliases | join(\"\\,\")")"
            lsrlist append newRow "$aliases"
        fi
        if [[ $INCLUDE_INITIALS == true ]]; then
            local initials="$(localsettings_eval ".gitusers.$user.initials // \" \"")"
            lsrlist append newRow "$initials"
        fi
        if [[ $INCLUDE_PHONE == true ]]; then
            local phone="$(localsettings_eval ".gitusers.$user.phone // \" \"")"
            lsrlist append newRow "$phone"
        fi
        if [[ $INCLUDE_EMAIL == true ]]; then
            local email="$(localsettings_eval ".gitusers.$user.email // \" \"")"
            lsrlist append newRow "$email"
        fi

        rows+=("$newRow")
        ((index++))
    done <<< "$(localsettings_eval ".gitusers | to_entries | .[] | .key")"

    table "$headers" "${rows[@]}"
}

git_users_get() {
    # Get the needed values
    local identifier=$(prompt_if_not_exists "Identifier" $1)
    
    localsettings_reformat

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    localsettings_eval ".gitusers.\"$identifier\""
}

git_users_new() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\\\"$identifier\\\"")
    if [[ ! "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier already exists"
        return 1
    fi

    local fullname=$(prompt_if_not_exists "Fullname" $2)

    # Set the values to the local settings
    localsettings_eval_with_save ".gitusers.\"$identifier\".fullname = \"$fullname\"" > /dev/null
    localsettings_eval_with_save ".gitusers.\"$identifier\".aliases = [ \"$fullname\" ]" > /dev/null
    localsettings_reformat
    print_success "Created gituser \"$identifier\""
}

git_users_delete() {
    # Get the needed values
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if not exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exists"
        return 1
    fi

    localsettings_delete ".gitusers.\"$identifier\""
    print_success "Deleted gituser \"$identifier\""
}

git_users_set_alias() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local alias=$(prompt_if_not_exists "Alias" $2)

    localsettings_eval_with_save ".gitusers.\"$identifier\".aliases += [ \"$alias\" ]"

    print_success "Added alias '$alias' to gituser '$identifier'"

    localsettings_reformat
}

git_users_unset_alias() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local alias=$(prompt_if_not_exists "Alias" $2)

    localsettings_eval_with_save "del(.gitusers.\"$identifier\".aliases[] | select(. == \"$alias\"))"

    print_success "Deleted alias '$alias' to gituser '$identifier'"

    localsettings_reformat
}

git_users_set_initials() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local initials=$(prompt_if_not_exists "Initials" $2)
    localsettings_eval_with_save ".gitusers.\"$identifier\".initials = \"$initials\""
    print_success "Updated initials for gituser '$identifier'"
    localsettings_reformat
}

git_users_set_phone() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local phone=$(prompt_if_not_exists "phone" $2)
    localsettings_eval_with_save ".gitusers.\"$identifier\".phone = \"$phone\""
    print_success "Updated phone for gituser '$identifier'"
    localsettings_reformat
}

git_users_set_email() {
    local identifier=$(prompt_if_not_exists "Identifier" $1)

    # Attempt get, if already exists, error
    local getResult=$(localsettings_eval ".gitusers.\"$identifier\"")
    if [[ "$getResult" == "null" ]]; then
        print_error "Git user with identifier $identifier does not exist"
        return 1
    fi

    local email=$(prompt_if_not_exists "email" $2)
    localsettings_eval_with_save ".gitusers.\"$identifier\".email = \"$email\""
    print_success "Updated email for gituser '$identifier'"
    localsettings_reformat
}