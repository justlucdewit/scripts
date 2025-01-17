source "./lsr.core.sh"

LSR_SET_COMMAND "repowatch"
LSR_SET_SUBCOMMAND "list"
LSR_SET_SUBCOMMAND "stats"
LSR_SET_SUBCOMMAND "logs"
LSR_SET_SUBCOMMAND "branches"
LSR_SET_SUBCOMMAND "changes"

LSR_DESCRIBE_SUBCOMMAND "list" "Show a list of all repositories that exist in your environment"
LSR_DESCRIBE_SUBCOMMAND "stats" "Show stats of a specific repository"
LSR_DESCRIBE_SUBCOMMAND "logs" "Show a log of all repository activity"
LSR_DESCRIBE_SUBCOMMAND "branches" "List out all of the branches the given repository"
LSR_DESCRIBE_SUBCOMMAND "changes" "Shows you what changes belongs to a specific commit hash of a specific project"

LSR_HANDLE_COMMAND "$@"

exit 0

LSR_CLI_INPUT_PARSER -ba --verbose test tta --title=window --description="this is a test"

if LSR_IS_FLAG_ENABLED "-a"; then
    echo "Flag -a was given"
else
    echo "Flag -a was not given"
fi

if LSR_IS_FLAG_ENABLED "--verbose"; then
    echo "Flag --verbose was given"
else
    echo "Flag --verbose was not given"
fi

if LSR_PARAMETER_GIVEN "--title"; then
    echo "Flag --title was given and its value is $(LSR_PARAMETER_VALUE "--title")"
else
    echo "Flag --title was not given"
fi

if LSR_PARAMETER_GIVEN "--description"; then
    echo "Flag --description was given and its value is $(LSR_PARAMETER_VALUE "--description")"
else
    echo "Flag --description was not given"
fi

echo "left over arguments => ${LSR_PARSED_ARGUMENTS[@]}"