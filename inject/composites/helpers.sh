# Helpers for making commands with subcommands

CURRENT_COMPOSITE_COMMAND=""
CURRENT_COMPOSITE_HELP_OVERWRITE=""
declare -g CURRENT_COMPOSITE_SUBCOMMANDS=()

composite_help_overwrite() {
    CURRENT_COMPOSITE_HELP_OVERWRITE="$1"
}

composite_define_command() {
    CURRENT_COMPOSITE_COMMAND="$1"
    CURRENT_COMPOSITE_SUBCOMMANDS=()
    CURRENT_COMPOSITE_HELP_OVERWRITE=""
    unset CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS
    declare -g CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS=()
    unset CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS
    declare -gA CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS
}

composite_define_subcommand() {
    local subcommand="$1"
    local parameters="$2"

    CURRENT_COMPOSITE_SUBCOMMANDS+=("$subcommand")
    CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS["$subcommand"]="$parameters"
}

composite_define_subcommand_description() {
    local subcommand="$1"
    local description="$2"

    CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS["$subcommand"]="$description"
}

composite_print_help_message() {
    echo -e "${LSR_STYLE_UNDERLINE}Usage:${LSR_STYlE_RESET}\n " $CURRENT_COMPOSITE_COMMAND "[COMMAND]" "[ARGUMENTS]" "[OPTIONS]\n"

    echo -e "${LSR_STYLE_UNDERLINE}Commands:${LSR_STYlE_RESET}"

    # Start with 4 due to 'help' command
    local longest_command_length=4
    for subcommand in "${CURRENT_COMPOSITE_SUBCOMMANDS[@]}"; do
        local subcommand_length=${#subcommand}
        if [[ "$subcommand_length" -gt "$longest_command_length" ]]; then
            longest_command_length=$subcommand_length
        fi
    done

    # Print all subcommands with their description
    echo -n "  help"
    echo "$(str_repeat " " "$((longest_command_length - 4))") Show this help message"
    for subcommand in "${CURRENT_COMPOSITE_SUBCOMMANDS[@]}"; do
        echo -n "  $subcommand" #  ${CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS[$subcommand]}



        if [[ -n "${CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS[$subcommand]}" ]]; then
            local current_command_command_length=${#subcommand}
            echo -n "$(str_repeat " " "$((longest_command_length - current_command_command_length))")"
            echo -n " ${CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS[$subcommand]}"
        fi

        echo
    done
}

composite_handle_subcommand() {
    local subcommand="$1"
    shift

    # If no sub command is given, print help
    if [[ ! -n "$subcommand" ]]; then
        if [[ -n "$CURRENT_COMPOSITE_HELP_OVERWRITE" ]]; then
            eval "${CURRENT_COMPOSITE_COMMAND}_$CURRENT_COMPOSITE_HELP_OVERWRITE $@"
            return
        fi

        composite_print_help_message
        return 0
    fi

    # Help sub command
    if [[ $subcommand == "help" ]]; then
        composite_print_help_message
    fi

    # If sub command is not defined, give error and print help
    if [[ ! -v CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS["$subcommand"] ]]; then
        print_error "Command '$CURRENT_COMPOSITE_COMMAND $subcommand' does not exist"
        composite_print_help_message
        return 1
    fi

    eval "${CURRENT_COMPOSITE_COMMAND}_$subcommand $@"
    return 0
}







# Helpers for flags and parameters

composite_help_get_flags() {
    reset_ifs
    local flags=()

    # Split the remaining arguments into flags (starts with --)
    for arg in "$@"; do
        if [[ "$arg" == *"="* ]]; then
            flagName="${arg%%=*}"  # Everything before the first '='
            value="${arg#*=}"      # Everything after the first '='
            arg="$flagName=\"$value\""
        fi

        if [[ "$arg" =~ ^-- ]]; then
            flags+=("$arg")
        elif [[ "$arg" =~ ^- ]]; then
            local splitCommand="$(echo t"${arg:1}" | fold -w1 | tr '\n' ' ')"
            for flag in $splitCommand; do
                flags+=("\"--$flag\"")
            done
        fi
    done

    # Assign the flags to the reference array
    echo "${flags[@]}"
}

composite_help_get_rest() {
    reset_ifs
    local non_flags=()

    # Split the remaining arguments into non-flags (does not start with --)
    for arg in "$@"; do
        arg=$(echo "$arg" | sed 's/"/__LSR_QUOTE_PLACEHOLDER__/g')
        if [[ (! "$arg" =~ ^--) && (! "$arg" =~ ^-) ]]; then
            non_flags+=("\"$arg\"")
        fi
    done

    echo "${non_flags[@]}" | sed 's/__LSR_QUOTE_PLACEHOLDER__/\"/g'
}

# Function to check if a flag is in the flags array
composite_help_contains_flag() {
    flagName=$1
    shift
    flags=("$@")

    for flag in "${flags[@]}"; do
        if [[ "$flag" == *"="* ]]; then
            flag="${flag%%=*}"  # Everything before the first '='
        fi

        if [[ "$flag" == "--$flagName" ]]; then
            return 0  # Flag is found
        fi
    done

    return 1  # Flag not found
}

composite_help_get_flag_value() {
    flagName=$1
    shift
    flags=("$@")

    for flag in "${flags[@]}"; do
        # Check if flag has an '=' sign
        if [[ "$flag" == "--$flagName="* ]]; then
            value="${flag#*=}"  # Extract everything after the '='
            echo "$value"        # Output the value to the caller
            return 0             # Success
        fi

        # Also support the form without '=' for a flag switch (optional)
        if [[ "$flag" == "--$flagName" ]]; then
            echo "true"          # For flags like --flag without a value
            return 0             # Success
        fi
    done

    return 1  # Flag not found
}

# Function to get the value of a flag
composite_help_flag_get_value() {
    flagName=$1
    shift
    flags=("$@")

    for flag in "${flags[@]}"; do
        if [[ "$flag" == "$flagName"* ]]; then
            # Extract the value after '='
            value="${flag#*=}"
            echo "$value"
            return
        fi
    done

    # Return an empty string if the flag doesn't have a value or isn't found
    echo ""
}
