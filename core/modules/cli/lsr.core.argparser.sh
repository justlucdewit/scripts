# Stand-alone module for parsing command arguments,
# This will take the entire input to the command as one single string, and then parse them to read the
# Flags - Simple words that refer to boolean true when present and false when not present (--verbose -v -h -vh)
# Parameters - Key value pairs starting with double dashes and an equal sign
# Arguments - Everything that is left, without starting dashes

declare -A LSR_PARSED_PARAMETERS
LSR_PARSED_FLAGS=()
LSR_PARSED_ARGUMENTS=()

# Function to check if a parameter is given
function LSR_PARAMETER_GIVEN() {
    local key="$1"
    if [[ -v LSR_PARSED_PARAMETERS["$key"] ]]; then
        return 0 # Parameter exists
    else
        return 1 # Parameter does not exist
    fi
}

# Function to get the value of a parameter
function LSR_PARAMETER_VALUE() {
    local key="$1"
    if [[ -v LSR_PARSED_PARAMETERS["$key"] ]]; then
        echo "${LSR_PARSED_PARAMETERS["$key"]}"
    else
        echo "" # Return empty string if parameter is not set
    fi
}


function LSR_CLI_INPUT_PARSER_RESET() {
    LSR_PARSED_FLAGS=()
    LSR_PARSED_ARGUMENTS=()
}

function LSR_CLI_INPUT_PARSER_ARGUMENTS_ADD() {
    local arg="$1"
    LSR_PARSED_ARGUMENTS+=("$arg")
}

function LSR_CLI_INPUT_PARSER_FLAGS_ENABLE() {
    local flag="$1"

    # Add the flag if its not added already
    if [[ ! " ${LSR_PARSED_FLAGS[@]} " =~ " ${flag} " ]]; then
        LSR_PARSED_FLAGS+=("$flag")
    fi
}

# Function to check if a flag is enabled
LSR_IS_FLAG_ENABLED() {
  local flag="$1"
  for enabled_flag in "${LSR_PARSED_FLAGS[@]}"; do
    if [[ "$enabled_flag" == "$flag" ]]; then
      return 0 # Flag is enabled
    fi
  done
  return 1 # Flag is not enabled
}

function LSR_CLI_INPUT_PARSER() {
    LSR_CLI_INPUT_PARSER_RESET
    local argument_count="$#"

    for arg_index in $(seq 1 $argument_count); do
        local argument_given="${!arg_index}"

        # Single letter flags
        if [[ "$argument_given" == "-"* && ! "$argument_given" == "--"* ]]; then
            # Handle grouped flags like -abc
            for ((i = 2; i <= ${#argument_given}; i++)); do
                local flag="-${argument_given:i-1:1}" # Extract each letter as a flag
                LSR_CLI_INPUT_PARSER_FLAGS_ENABLE "$flag" # Add to the flags array
            done

            continue
        fi
        
        # Multiletter flags/parameters
        if [[ "$argument_given" == "--"* ]]; then
            # Multiletter flags
            if [[ "$argument_given" != *"="* ]]; then
                LSR_CLI_INPUT_PARSER_FLAGS_ENABLE "$argument_given"
            fi

            # parameters
            if [[ "$argument_given" == *"="* ]]; then
                local key="${argument_given%%=*}"   # Extract the part before '='
                local value="${argument_given#*=}" # Extract the part after '='
                LSR_PARSED_PARAMETERS["$key"]="$value"
            fi

            continue
        fi

        # What stays over, is an argument
        if [[ "$argument_given" != "-"* ]]; then
            LSR_CLI_INPUT_PARSER_ARGUMENTS_ADD "$argument_given"
        fi
    done
}