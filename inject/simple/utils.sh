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
        header=$(echo -e "$header" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')
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
            local value=$(echo -e "${rowValues[i]}" | sed 's/__ESCAPED_COMMA__/,/g' | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')
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

        echo -ne "│ $header"
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
            local clean_value=$(echo -e "${rowValues[i]}" | sed 's/__ESCAPED_COMMA__/,/g' | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')
            local currColLength="${colLengths[i]}"
            local currValuelength="${#clean_value}"
            local numberOfSpacesNeeded="$((currColLength - currValuelength + 1))"

            # echo "<$numberOfSpacesNeeded>"

            echo -ne "│ $value"
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

printlist() {
    local listName=$1
    local listItems=$2
    
    eval "flags=($(composite_help_get_flags "$@"))"
    eval "args=($(composite_help_get_rest "$@"))"
    

    local selectable="false"
    local prefix=" - "
    local selected_prefix=" > "
    local selected_value=""

    if composite_help_contains_flag prefix "${flags[@]}"; then
        prefix=$(composite_help_get_flag_value prefix "${flags[@]}")
    fi
    
    if composite_help_contains_flag selected-prefix "${flags[@]}"; then
        selected_prefix=$(composite_help_get_flag_value selected-prefix "${flags[@]}")
    fi

    if composite_help_contains_flag selected "${flags[@]}"; then
        local selected_index=$(composite_help_get_flag_value selected "${flags[@]}")
        selected_value=$(lsrlist index listItems "$selected_index")
    fi

    echo "$listName:"

    IFS=',' # Set the Internal Field Separator to comma
    echo "$listItems" | yq eval '.[]' - | while read -r listItem; do
        if [[ "$listItem" == "$selected_value" ]]; then
            echo -e "$selected_prefix$listItem"
        else
            echo -e "$prefix$listItem"
        fi
    done
    reset_ifs
}

selectable_list() {
    local title=$1
    local -n return_ref=$2
    local options="$3"
    local selected_index=0
    local options_length=$(lsrlist length options)

    # Function to display the menu
    print_menu() {
        clear
        echo "Use Arrow Keys to navigate, Enter to select:"
        local selected_option=$(lsrlist index options)
        printlist "$title" "$options" "--selected=$selected_index" --selected-prefix="\e[1;32m => " --prefix="\e[0m  - "
        echo -ne "\e[0m"
    }

    # Capture arrow keys and enter key
    while true; do
        print_menu

        # Read one character at a time with `-s` (silent) and `-n` (character count)
        read -rsn1 input

        # Check for arrow keys or Enter
        case "$input" in
            $'\x1b')  # ESC sequence (for arrow keys)
                read -rsn2 -t 0.1 input  # Read next two chars
                case "$input" in
                    '[A')  # Up arrow
                        ((selected_index--))
                        if [ $selected_index -lt 0 ]; then
                            selected_index=$(($options_length - 1))
                        fi
                        ;;
                    '[B')  # Down arrow
                        ((selected_index++))
                        if [ $selected_index -ge $options_length ]; then
                            selected_index=0
                        fi
                        ;;
                esac
                ;;
            '')  # Enter key
                return_ref=$(lsrlist index options "$selected_index")
                break
                ;;
        esac
    done
}