localsettings_ensureexists() {
    # Dont do anything when using LSR-LITE since its config-less
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        return
    fi
    
    local field="$1"

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    local value=$(yq e "$field // \"\"" "$LSR_LOCAL_SETTINGS_FILE")

    # Create it if it does not exist
    if [[ -z "$value" ]]; then
        yq e -i "$field = null" "$LSR_LOCAL_SETTINGS_FILE"
        localsettings_reformat
    fi
}

localsettings_sort() {
    # Dont do anything when using LSR-LITE since its config-less
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        return
    fi

    local field=$1

    if [ "$#" -ne 1 ]; then
        field="."
    fi

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    localsettings_eval_with_save "$field = ($field | to_entries | sort_by(.key) | from_entries)"
}

localsettings_delete() {
    # Dont do anything when using LSR-LITE since its config-less
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        return
    fi

    local field=$1

    if [ "$#" -ne 1 ]; then
        echo "Usage: lsdel <path>"
        return 1  # Return an error code
    fi

    localsettings_eval_with_save "del($field)"
}

localsettings_eval_with_save() {
    # Dont do anything when using LSR-LITE since its config-less
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        return
    fi

    local command="."

    if [[ -n $1 ]]; then
        command="$1"
    fi

    yq e -iP "$command" "$LSR_LOCAL_SETTINGS_FILE"
}

localsettings_eval() {
    # Dont do anything when using LSR-LITE since its config-less
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        return
    fi

    local command="."

    if [[ -n $1 ]]; then
        command="$1"
    fi

    yq e -P "$command" "$LSR_LOCAL_SETTINGS_FILE"
}

localsettings_get() {
    # Dont do anything when using LSR-LITE since its config-less
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        return
    fi

    local allow_create=false
    local field="."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --allow-create)
                allow_create=true
                shift
                ;;
            *)
                field="$1"
                shift
                ;;
        esac
    done

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    if $allow_create; then
        localsettings_ensureexists "$field"
    fi
    
    yq e -P "$field" "$LSR_LOCAL_SETTINGS_FILE"
}

localsettings_set() {
    # Dont do anything when using LSR-LITE since its config-less
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        return
    fi

    local allow_create=false
    local field=""
    local value=""
    local unquoted=false

    # Display help message
    show_help() {
        print_normal "Usage: localsettings_set [OPTIONS] FIELD VALUE"
        print_normal "Set a value in the local settings file."
        print_normal ""
        print_normal "Options:"
        print_normal "  -a, --allow-create   Create the field if it doesn't exist."
        print_normal "  -u, --unquoted       Set the value without quotes."
        print_normal "  -h, --help           Display this help message."
        print_normal ""
        print_normal "Examples:"
        print_normal "  localsettings_set --allow-create .projects.aa '5'  # Set with quotes"
        print_normal "  localsettings_set --unquoted .projects.aa 5        # Set without quotes"
        print_normal "  localsettings_set .projects.aa '5'                  # Set with quotes"
        print_normal "  localsettings_set --help                             # Display help"
    }

    # Parse options using getopts
    while getopts "auh" opt; do
        case "$opt" in
            a) allow_create=true ;;
            u) unquoted=true ;;
            h) show_help; return 0 ;;
            \?) print_normal "Invalid option: -$OPTARG" >&2; return 1 ;;
            :) print_normal "Option -$OPTARG requires an argument." >&2; return 1 ;;
        esac
    done

    # Shift off the options processed by getopts
    shift $((OPTIND - 1))

    # Now handle long options manually
    for arg in "$@"; do
        case "$arg" in
            --allow-create)
                allow_create=true
                ;;
            --unquoted)
                unquoted=true
                ;;
            --help)
                show_help
                return 0
                ;;
            *)
                # Capture field and value
                if [[ -z "$field" ]]; then
                    field="$arg"  # First non-flag argument is the field
                elif [[ -z "$value" ]]; then
                    value="$arg"  # Second non-flag argument is the value
                else
                    print_normal "Error: Too many arguments." >&2
                    return 1
                fi
                ;;
        esac
    done

    # Check that both field and value are provided
    if [[ -z "$field" || -z "$value" ]]; then
        print_normal "Error: FIELD and VALUE are required." >&2
        return 1
    fi

    # Ensure field starts with a dot
    if [[ "$field" != .* ]]; then
        field=".$field"
    fi

    # Validate the field before proceeding
    if ! yq_validate_only_lookup "$field"; then
        return 1  # Exit if validation fails
    fi

    # Ensure the field exists, conditionally
    if $allow_create; then
        localsettings_ensureexists "$field"
    fi

    print_normal "$unquoted"

    # Set the value
    if [[ $unquoted == "true" ]]; then
        # Set without quotes
        print_normal "YEEE"
        print_normal "yq e -i \"$field=$value\" \"$LSR_LOCAL_SETTINGS_FILE\""
        yq e -i "$field=$value" "$LSR_LOCAL_SETTINGS_FILE"
    else
        # Set with quotes
        yq e -i "$field=\"$value\"" "$LSR_LOCAL_SETTINGS_FILE"
    fi
}

yq_validate_only_lookup() {
    local field="$1"

    # Allow just a dot to return the entire structure
    if [[ "$field" == "." ]]; then
        return 0  # Valid case for root access
    fi

    # Regular expression to match valid field patterns
    if [[ ! "$field" =~ ^\.[a-zA-Z_-][a-zA-Z0-9_.-]*(\[[0-9]+\])?(\.[a-zA-Z_-][a-zA-Z0-9_.-]*(\[[0-9]+\])?)*$ ]]; then
        print_error "Invalid field format '${field}'. Only lookup notation is allowed (e.g., .projects or .projects.test-example).\n"
        return 1  # Exit with an error
    fi

    return 0
}

localsettings_reformat() {
    # Dont do anything when using LSR-LITE since its config-less
    if [[ "$LSR_TYPE" == "LSR-LITE" ]]; then
        return
    fi

    yq e -P '.' -i "$LSR_LOCAL_SETTINGS_FILE"
    localsettings_sort .projects
    localsettings_sort .gitusers
    localsettings_sort .
}