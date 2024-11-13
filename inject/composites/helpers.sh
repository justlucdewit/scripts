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

        arg=$(echo "$arg" | sed "s/ /__LSR_SPACE_PLACEHOLDER__/g")

        if [[ "$arg" =~ ^-- ]]; then
            flags+=("$arg")
        elif [[ "$arg" =~ ^- ]]; then
            local splitCommand="$(echo "${arg:1}" | fold -w1 | tr '\n' ' ')"
            for flag in $splitCommand; do
                flags+=("--$flag")
            done
        fi
    done

    # Assign the flags to the reference array
    echo "${flags[@]}"
}

# Function to check if a flag is in the flags array
composite_help_contains_flag() {
    flagName=$1
    shift
    flags=("$@")

    echo "total => ${flags[@]}"

    for flag in "${flags[@]}"; do

        if [[ "$flag" == *"="* ]]; then
            flag="${arg%%=*}"  # Everything before the first '='
        fi

        echo " comparing $flag with --$flagName"

        if [[ "$flag" == "--$flagName" ]]; then
            return 0  # Flag is found
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

composite_help_get_rest() {
    reset_ifs
    local non_flags=()

    # Split the remaining arguments into non-flags (does not start with --)
    for arg in "$@"; do
        if [[ (! "$arg" =~ ^--) && (! "$arg" =~ ^-) ]]; then
            non_flags+=("$arg")
        fi
    done

    echo "${non_flags[@]}"
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