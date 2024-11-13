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
    else
        print_error "Command $command does not exist"
        git_users_main_command # Re-run for help command
    fi
}

git_users_list() {
    # localsettings_reformat
    # localsettings_get .gitusers

    users=$(localsettings_get .gitusers)
    headers='Index,Identifier,Full name,Aliases'
    rows=()

    index=0
    while IFS= read -r user; do
        fullname="$(lsget .gitusers.$user.fullname)"
        aliases="$(lseval ".gitusers.$user.aliases | join(\"\\,\")")"

        rows+=("$index,$user,$fullname,$aliases")
        # # Increment the index
        ((index++))
    done <<< "$(lseval ".gitusers | to_entries | .[] | .key")"

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