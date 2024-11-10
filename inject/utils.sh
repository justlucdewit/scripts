# TODO:
# - table command
# - scrollTable command
# - actionTable command
# - select command
# - list command
# - confirm command
# - progressbar command

table() {
    local header
    local colCount=3
    local colLengths=(2 3 4)

    # Print the top bar
    echo -n "┌"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $colLength))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┬"
        fi
        ((currentColIndex++))
    done
    echo -n "┐"
    echo ""

    # Print header bar


    # Print header bottom
    echo -n "├"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $colLength))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┼"
        fi
        ((currentColIndex++))
    done
    echo -n "┤"
    echo ""

    # Print the bottom bar
    echo -n "└"
    local currentColIndex=1
    for colLength in "${colLengths[@]}"; do
        echo -n "$(printf '─%.0s' $(seq 1 $colLength))"
        if [[ $currentColIndex != $colCount ]]; then
            echo -n "┴"
        fi
        ((currentColIndex++))
    done
    echo -n "┘"
    echo ""
}

table 'Index Identifier "Full Name" Aliases'