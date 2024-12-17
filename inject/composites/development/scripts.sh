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
    composite_define_subcommand "list" # Todo: lsrignore
    composite_define_subcommand "new" "<script-name>"
    composite_define_subcommand "find" "<script-name>"
    composite_define_subcommand "run" "<script-name>"
    composite_define_subcommand "edit" "<script-name>"
    composite_help_overwrite "list"
    composite_handle_subcommand $@
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

# Finds scripts to fall back on, in one of the following directories:
# .                 the root dir
# ./scripts/        the local unignored scripts
# ./_lsr_scripts    the local ignored scripts
# If the script name starts with an underscore, it is hidden and thus not listed nor callable
# - bash scripts
# - python scripts
# - nodejs scripts
scripts_list() {
    if [[ $(find . -maxdepth 1 -wholename "./*.sh" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.sh" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.sh" -print -quit)) ]]; then
        echo "Bash scripts:"
    fi
    for file in ./*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*" && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    for file in ./scripts/*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    for file in ./_lsr_scripts/*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then

            if [[ -f "./_lsr_scripts/.lsrignore" && -n $(cat "./_lsr_scripts/.lsrignore" | grep "^$file$") ]]; then
                continue
            fi
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.sh" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.sh" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.sh" -print -quit)) ]]; then
        echo ""
    fi

    if [[ $(find . -maxdepth 1 -wholename "./*.py" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.py" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.py" -print -quit)) ]]; then
        echo "Python scripts:"
    fi
    for file in ./*.py; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.py}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo "- $basename"
        fi
    done
    for file in ./scripts/*.py; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.py}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.py" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.py" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.py" -print -quit)) ]]; then
        echo ""
    fi
    
    if [[ $(find . -maxdepth 1 -wholename "./*.js" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*js" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.js" -print -quit)) ]]; then
        echo "Node scripts:"
    fi
    for file in ./*.js; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.js}"  # Remove the .js suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo "- $basename"
        fi
    done
    for file in ./scripts/*.js; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.js}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.js" -print -quit)  || ( -d ./scripts && $(find ./scripts -wholename "*.js" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.js" -print -quit)) ]]; then
        echo ""
    fi

    local hasPrintedNpmScripts="false"
    if [[ -f "./package.json" ]]; then
        scripts=$(jq '.scripts' package.json)
        if [[ "$scripts" != "null" && "$scripts" != "{}" && -n "$scripts" ]]; then
            local npmscripts=$(jq -r ".scripts | keys[]" ./package.json)

            while IFS= read -r line; do
                if [[ -f "./_lsr_scripts/.lsrignore" && -n $(cat "./_lsr_scripts/.lsrignore" | grep "^npm@$line$") ]]; then
                    continue
                fi

                if [[ "$hasPrintedNpmScripts" == "false" ]]; then
                    hasPrintedNpmScripts="true"
                    echo "Npm scripts:"
                fi
                
                echo " - $line"
            done <<< "$npmscripts"

            if [[ "$hasPrintedNpmScripts"=="true" ]]; then
                echo ""
            fi
        fi
    fi
}