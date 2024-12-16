# This bash file makes sure that if a command is not found, bash can fallback on some script that it can find in certain directories

command_not_found_handle() {
    cmd="$1"

    # When command is not found, fallback on scripts
    # If the script name starts with an underscore, it is hidden and thus not listed nor callable
    # Location Priority:
    #   - In current directory
    #   - In ./_lsr_scripts folder
    #   - In ./scripts/ folder
    # Language Priority:
    #   - .sh scripts
    #   - .py scripts
    #   - .js scripts
    #   - npm scripts
    
    # Run the bash script if it exists
    if [[ $cmd != _* ]]; then
        if [[ -f "./$cmd.sh" ]]; then # Run the script
            print_info "Running script $cmd.sh"
            bash "./$cmd.sh" "${@:2}"
            return

        # Run the /_lsr_scripts/ bash script if it exists
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.sh" ]]; then
            print_info "Running script $cmd.sh"
            bash "./_lsr_scripts/$cmd.sh" "${@:2}"
            return

        # Run the /scripts/ bash script if it exists
        elif [[ -d "./scripts" && -f "./scripts/$cmd.sh" ]]; then
            print_info "Running script $cmd.sh"
            bash "./scripts/$cmd.sh" "${@:2}"
            return

        # Run the python script if it exists
        elif [[ -f "./$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./$cmd.py" "${@:2}"
            return

        # Run the /_lsr_scripts/ python script if it exists
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./_lsr_scripts/$cmd.py" "${@:2}"
            return

        # Run the /scripts/ python script if it exists
        elif [[ -d "./scripts" && -f "./scripts/$cmd.py" ]]; then
            print_info "Running script $cmd.py"
            python3 "./scripts/$cmd.py" "${@:2}"
            return

        # Run the js script if it exists
        elif [[ -f "./$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./$cmd.js" "${@:2}"
            return

        # Run the /_lsr_scripts/ js script if it exists
        elif [[ -d "./_lsr_scripts" && -f "./_lsr_scripts/$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./_lsr_scripts/$cmd.js" "${@:2}"
            return

        # Run the /scripts/ js script if it exists
        elif [[ -d "./scripts" && -f "./scripts/$cmd.js" ]]; then
            print_info "Node script $cmd.js"
            node "./scripts/$cmd.js" "${@:2}"
            return

        # Run the script from the npm folder if it exists
        elif [[ -f "./package.json" && "$(grep \"$cmd\": package.json)" != "" ]]; then
            print_info "Running NPM script '$cmd'"
            npm run $cmd --silent
            return
        fi
    fi

    # Command was not found
    suggestions=$(compgen -c "$cmd" | head -n 5)
    if [[ -n "$suggestions" ]]; then
        echo "bash: $cmd: command not found. Did you mean one of these?"
        echo " - $suggestions" | while read -r suggestion; do echo "  $suggestion"; done
    else
        echo "bash: $cmd: command not found"
    fi
    return 127
}

# Default commands to overwritten_commands
# check_for_command_overwrite() {
#     local command=$1
#     local subcommand=$2

#     overwrite_name="lsr_overwrite_${command}_${subcommand}"
    
#     if echo "$(declare -f)" | grep "^$overwrite_name ()" > /dev/null 2>&1; then
#         echo "$overwrite_name"
#         return 1
#     fi

#     return 0
# }

# lsr_overwrite_git_stats() {
#     echo "git statistics overwrite"
# }

# shopt -s extdebug
# trap 'check_for_command_overwrite $BASH_COMMAND' DEBUG
