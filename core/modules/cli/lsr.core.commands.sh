CURRENT_COMPOSITE_COMMAND=""
CURRENT_COMPOSITE_HELP_OVERWRITE=""
declare -g CURRENT_COMPOSITE_SUBCOMMANDS=()

composite_help_overwrite() {
    CURRENT_COMPOSITE_HELP_OVERWRITE="$1"
}

LSR_SET_COMMAND() {
    CURRENT_COMPOSITE_COMMAND="$1"
    CURRENT_COMPOSITE_SUBCOMMANDS=()
    CURRENT_COMPOSITE_HELP_OVERWRITE=""
    unset CURRENT_COMPOSITE_SUBCOMMAND_ARGUMENTS
    declare -gA CURRENT_COMPOSITE_SUBCOMMAND_ARGUMENTS=()

    unset CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS
    declare -gA CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS

    unset CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER_DESCRIPTION
    declare -gA CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER_DESCRIPTION

    unset CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER
    declare -gA CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER
}

LSR_SET_SUBCOMMAND() {
    local subcommand="$1"
    local arguments="$2"

    CURRENT_COMPOSITE_SUBCOMMANDS+=("$subcommand")
    CURRENT_COMPOSITE_SUBCOMMAND_ARGUMENTS["$subcommand"]="$arguments"
}

LSR_DESCRIBE_SUBCOMMAND() {
    local subcommand="$1"
    local description="$2"

    CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS["$subcommand"]="$description"
}

composite_define_subcommand_parameter() {
    local subcommand="$1"
    local parameter="$2"
    local description="$3"

    CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER["$subcommand/$parameter"]="$parameter"
    CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER_DESCRIPTION["$subcommand/$parameter"]="$description"
}

composite_print_help_message() {
    # Help overwrite
    if [[ -n "$CURRENT_COMPOSITE_HELP_OVERWRITE" ]]; then
        eval "${CURRENT_COMPOSITE_COMMAND}_$CURRENT_COMPOSITE_HELP_OVERWRITE $@"
        return
    fi

    echo -e "${LSR_STYLE_UNDERLINE}Usage:${LSR_STYlE_RESET}\n " $CURRENT_COMPOSITE_COMMAND "[COMMAND]" "[ARGUMENTS]" "\n"
    echo -e "${LSR_STYLE_UNDERLINE}Commands:${LSR_STYlE_RESET}"

    # Start with 4 due to 'help' command
    local longest_command_length=4
    for subcommand in "${CURRENT_COMPOSITE_SUBCOMMANDS[@]}"; do

        local argument_description=${CURRENT_COMPOSITE_SUBCOMMAND_ARGUMENTS["$subcommand"]}
        if [[ -n "$argument_description" ]]; then
            argument_description=" $argument_description"
        fi

        local text="$subcommand$argument_description "
        local subcommand_length=${#text}
        if [[ "$subcommand_length" -gt "$longest_command_length" ]]; then
            longest_command_length=$subcommand_length
        fi
    done

    # Print all subcommands with their description
    echo -n "  help"
    echo "$(str_repeat " " "$((longest_command_length - 4))") Show this help message"
    for subcommand in "${CURRENT_COMPOSITE_SUBCOMMANDS[@]}"; do
        local argument_description=${CURRENT_COMPOSITE_SUBCOMMAND_ARGUMENTS["$subcommand"]}
        if [[ -n "$argument_description" ]]; then
            argument_description=" $argument_description"
        fi
        
        echo -n "  $subcommand$argument_description " #  ${CURRENT_COMPOSITE_SUBCOMMAND_ARGUMENTS[$subcommand]}

        if [[ -n "${CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS[$subcommand]}" ]]; then
            local text="$subcommand$argument_description "
            local current_command_command_length=${#text}
            echo -n "$(str_repeat " " "$((longest_command_length - current_command_command_length))")"
            echo -n " ${CURRENT_COMPOSITE_SUBCOMMAND_DESCRIPTIONS[$subcommand]}"
        fi

        echo

        local longest_parameter_length=1
        for key in "${!CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER[@]}"; do
            local value="${CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER[$key]}"
            if [[ "$key" == "$subcommand/"* && "${#value}" -gt "$longest_parameter_length" ]]; then
                longest_parameter_length="${#value}"
            fi
        done

        for key in "${!CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER[@]}"; do
            if [[ "$key" == "$subcommand/"* ]]; then
                local value="${CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER[$key]}"
                local value_length="${#value}"

                local description="${CURRENT_COMPOSITE_SUBCOMMAND_PARAMETER_DESCRIPTION[$subcommand/$value]}"
                echo "    $value$(str_repeat " " "$((longest_parameter_length - value_length))") $description"
            fi
        done
    done
}

LSR_HANDLE_COMMAND() {
    local subcommand="$1"
    shift

    # Help sub command
    if [[ "$subcommand" == "" || "$subcommand" == "help" ]]; then
        composite_print_help_message
        return 0
    fi

    for attempted_subcommand in "${CURRENT_COMPOSITE_SUBCOMMANDS[@]}"; do
        if [[ "$attempted_subcommand" == "$subcommand" ]]; then
            eval "${CURRENT_COMPOSITE_COMMAND}_$subcommand \"$@\""
            return 0
        fi
    done

    echo "Error: Command '$CURRENT_COMPOSITE_COMMAND $subcommand' does not exist"
    echo "Error: Try '$CURRENT_COMPOSITE_COMMAND help' instead"
    return 1
}