# TODO:
# - scrollTable command
# - actionTable command
# - select command
# - list command
# - confirm command
# - progressbar command

table() {
    local header_csv="$1"
    IFS=',' read -r -a headers <<< "$header_csv"

    # Parse the headers and save the lengths
    local colCount="${#headers[@]}"
    local colLengths=()
    for header in "${headers[@]}"; do
        local headerLength="${#header}"
        colLengths+=("$headerLength")
    done

    shift

    # Loop trough the body, looking if we need to extend the col width
    for row in "${@:1}"; do

        # Replace escaped commas with a placeholder
        row=$(echo "$row" | sed 's/\\,/__ESCAPED_COMMA__/g')

        IFS=',' read -r -a rowValues <<< "$row"
        for ((i = 0; i < ${#rowValues[@]}; i++)); do
            local value=$(echo "${rowValues[i]}" | sed 's/__ESCAPED_COMMA__/,/g')
            local valueLength="${#value}"
            local currColWidth="${colLengths[i]}"

            if [[ $valueLength -gt $currColWidth ]]; then
                colLengths[$i]="$valueLength"
            fi

        done
    done

    # Print the top bar
    echo -n "┌"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $((colLength + 2))))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┬"
        fi
        ((currentColIndex++))
    done
    echo -n "┐"
    echo ""

    # Print header bar
    for ((i = 0; i < ${#headers[@]}; i++)); do
        local header="${headers[i]}"
        local headerLength="${colLengths[i]}"
        local currHeaderLength="${#header}"

        echo -n "│ $header"
        echo -n "$(printf ' %.0s' $(seq 1 $(( headerLength - currHeaderLength + 1 ))))"
    done
    echo "│"

    # Print header bottom
    echo -n "├"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $((colLength + 2))))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┼"
        fi
        ((currentColIndex++))
    done
    echo -n "┤"
    echo ""

    # Print the table body
    for row in "${@:1}"; do
        
        # Replace escaped commas with a placeholder
        row=$(echo "$row" | sed 's/\\,/__ESCAPED_COMMA__/g')

        IFS=',' read -r -a rowValues <<< "$row"
        for ((i = 0; i < ${#rowValues[@]}; i++)); do
            local value=$(echo "${rowValues[i]}" | sed 's/__ESCAPED_COMMA__/,/g')
            local currColLength="${colLengths[i]}"
            local currValuelength="${#value}"
            local numberOfSpacesNeeded="$((currColLength - currValuelength + 1))"

            echo -n "│ $value"
            echo -n "$(printf ' %.0s' $(seq 1 $numberOfSpacesNeeded))"
        done
        echo "│"
    done

    # Print the bottom bar
    echo -n "└"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $((colLength + 2))))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┴"
        fi
        ((currentColIndex++))
    done
    echo -n "┘"
    echo ""
}

list() {
    # Get the flags and arguments
    read -r -a flags <<< "$(composite_help_get_flags "$@")"
    read -r -a args <<< "$(composite_help_get_rest "$@")"

    if composite_help_contains_flag style-numeric "${flags[@]}"; then
        echo "Does contain it"
    else
        echo "Does not contain it"
    fi

    return
    set -- "${args[@]}"

    local listName=$1
    local listItems=$2

    echo "$listName:"

    IFS=',' # Set the Internal Field Separator to comma
    for listItem in $listItems; do
        echo " - $listItem"
    done
    reset_ifs
}

# list "names" "A,B,C,D" --style-numeric="this is a test" --eep=helloworld -abd --ree