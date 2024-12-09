CURRENT_COMPOSITE_COMMAND=""
declare -g CURRENT_COMPOSITE_SUBCOMMANDS=()

composite_define_command() {
    CURRENT_COMPOSITE_COMMAND="$1"
    CURRENT_COMPOSITE_SUBCOMMANDS=()
    unset CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS
    declare -gA CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS
}

composite_define_subcommand() {
    local subcommand="$1"
    local parameters="$2"

    CURRENT_COMPOSITE_SUBCOMMANDS+=("$subcommand")
    CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS["$subcommand"]="$parameters"
}

composite_print_help_message() {
    echo "Usage: "

    for subcommand in "${CURRENT_COMPOSITE_SUBCOMMANDS[@]}"; do
        echo "  - $CURRENT_COMPOSITE_COMMAND $subcommand ${CURRENT_COMPOSITE_SUBCOMMANDS_PARAMETERS[$subcommand]}"
    done
}

composite_handle_subcommand() {
    local subcommand="$1"
    shift

    # If no sub command is given, print help
    if [[ ! -n "$subcommand" ]]; then
        composite_print_help_message
        return 0
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
S
    # Split the remaining arguments into non-flags (does not start with --)
    for arg in "$@"; do
        # arg=$(echo "$arg" | sed "s/ /__LSR_SPACE_PLACEHOLDER__/g")
        if [[ (! "$arg" =~ ^--) && (! "$arg" =~ ^-) ]]; then
            non_flags+=("\"$arg\"")
        fi
    done

    echo "${non_flags[@]}"
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

# Helper functions for creating composite commands
composite_help_command() {
    
    # Arguments
    local filter=$1               # Filter for what help commands to show
    local argument_count=$2       # Number of arguments
    shift 2
    echo "$2"

    return
    local defined_commands=("$@")  # List of commands

    # Dont do anything if any arguments were given to the main function
    if [ "$argument_count" -gt 0 ]; then
        return
    fi

    # lcompIterate over the commands and print only the ones that match the filter
    echo "Usage: '${defined_commands[@]}' "
    for cmd in "${defined_commands[@]}"; do
        echo " - $cmd"

        # if [[ "$filter" == "" || "$cmd" == "$filter"* ]]; then
            
        #     # echo " - "
        # fi
    done
}