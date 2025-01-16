# Stand-alone module for parsing command arguments,
# This will take the entire input to the command as one single string, and then parse them to read the
# Flags - Simple words that refer to boolean true when present and false when not present (--verbose -v -h -vh)
# Parameters - Key value pairs starting with double dashes and an equal sign
# Arguments - Everything that is left, without starting dashes

declare -A LSR_PARSED_ARGUMENTS
LSR_PARSED_FLAGS=()
LSR_PARSED_ARGUMENTS=()

function LSR_CLI_INPUT_PARSER() {
    local argument_count="$#"

    echo "received $argument_count arguments"

    echo " => '$1'"
    echo " => '$2'"
    echo " => '$3'"
    echo " => '$4'"
    echo " => '$5'"
    echo " => '$6'"

    # Add a flag as a test
    LSR_PARSED_FLAGS+=("aaa")

    # Print all entries in the flags
}