alias scripts="scripts_main_command"

initialize_scripts_dir() {
    # Dont do anything if lsr scripts dir already exists
    if [[ -d "./_lsr_scripts" ]]; then
        return
    fi

    # Dont do anything if current directory is not a git repo
    if [[ ! -d "./.git" ]]; then
        return
    fi

    # Create the lsr directory and also create the bmr config file
    mkdir -p "./_lsr_scripts"
    {
        echo "[project]"
        echo "repo_name="
        echo "repo_url="
        echo ""
        echo "[environment dev]"
        echo "url="
        echo "directory="
        echo "database="
    } > "./_lsr_scripts/config.bmr"
}

scripts_main_command() {
    initialize_scripts_dir

    composite_define_command "scripts"
    composite_define_subcommand "list"
    composite_define_subcommand "run" "<script-name>"
    composite_define_subcommand "select"
    composite_define_subcommand "new" "<script-name>"
    composite_define_subcommand "find" "<script-name>"
    composite_define_subcommand "edit" "<script-name>"
    composite_help_overwrite "list"
    composite_handle_subcommand $@
}

scripts_select() {
    local scripts_output=$(scripts list)
    local scripts_list=$(echo "$scripts_output" | grep '^ - ' | awk '{sub(/^ - /, ""); if (NR > 1) printf ","; printf "\"%s\"", $0} END {print ""}')
    scripts_list="[$scripts_list]"

    local value=""
    selectable_list "Select a script" value "$scripts_list"
    $value
}

scripts_run() {
    local scriptName="$1"
    shift
    local scriptFile=$(scripts_find "$scriptName")

    if [[ -z "$scriptFile" ]]; then
        print_error "Could not find script named $scriptName"
        return
    fi

    if [[ "$scriptFile" == *".py" ]]; then
        python3 "$scriptFile" "$@"
    fi

    if [[ "$scriptFile" == *".sh" ]]; then
        bash "$scriptFile" "$@"
    fi

    if [[ "$scriptFile" == *".js" ]]; then
        node "$scriptFile" "$@"
    fi

    if [[ "$scriptFile" == "npm@"* ]]; then
        npmScript="${scriptFile#npm@}"
        npm run "$npmScript"
    fi
}

scripts_edit() {
    local scriptName="$1"
    shift
    local scriptFile=$(scripts_find "$scriptName")

    if [[ -z "$scriptFile" ]]; then
        print_error "Could not find script named $scriptName"
        return
    fi

    if [[ "$scriptFile" == *".js" || "$scriptFile" == *".sh" || "$scriptFile" == *".py" ]]; then
        vim "$scriptFile"
    fi

    if [[ "$scriptFile" == "npm@"* ]]; then
        vim "./package.json"
    fi
}

scripts_find() {
    local scriptName="$1"

    for file in ./*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" == "$scriptName" ]]; then
            echo "$file"
            return
        fi
    done
    for file in ./scripts/*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" == "$scriptName" ]]; then
            echo "$file"
            return
        fi
    done
    for file in ./_lsr_scripts/*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" == "$scriptName" ]]; then
            echo "$file"
            return
        fi
    done
    for file in ./*.py; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.py}"  # Remove the .py suffix

        if [[ "$basename" == "$scriptName" ]]; then
            echo "$file"
            return
        fi
    done
    for file in ./scripts/*.py; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.py}"  # Remove the .py suffix

        if [[ "$basename" == "$scriptName" ]]; then
            echo "$file"
            return
        fi
    done
    for file in ./*.js; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.js}"  # Remove the .js suffix

        if [[ "$basename" == "$scriptName" ]]; then
            echo "$file"
            return
        fi
    done
    for file in ./scripts/*.js; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.js}"  # Remove the .py suffix

        if [[ "$basename" == "$scriptName" ]]; then
            echo "$file"
            return
        fi
    done

    if [[ -f "./package.json" ]]; then
        script=$(jq -r ".scripts | to_entries | map(select(.key == \"$scriptName\"))[0].key" ./package.json)
        if [[ "$script" != "null" && "$script" != "{}" && -n "$script" ]]; then
            echo "npm@$scriptName"
            return
        fi
    fi
}

scripts_new() {
    local scriptName="$1"
    touch "./_lsr_scripts/$scriptName.sh"
    {
        echo "source \"$HOME/scripts/versions/dev/build.sh\""
    } > "./_lsr_scripts/$scriptName.sh"
}

