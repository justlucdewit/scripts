# Composite command
lsrlist() {
    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - lsrlist create <listname>"
        echo "  - lsrlist append <listname> <item>"
        echo "  - lsrlist index <listname> <index>"
        echo "  - lsrlist length <listname> <index>"
        return 0
    fi

    local command=$1
    local -n list_ref=$2
    shift
    shift

    if is_in_list "$command" "create"; then
        lsrlist_create list_ref $@
    elif is_in_list "$command" "append"; then
        lsrlist_append list_ref "$@"
    elif is_in_list "$command" "length"; then
        lsrlist_length list_ref "$@"
    elif is_in_list "$command" "index"; then
        lsrlist_index list_ref "$@"
    else
        print_error "Command $command does not exist"
        lsrlist # Re-run for help command
    fi
}

lsrlist_index() {
    local -n list=$1
    local index=$2

    # If the list is empty, print a message and return
    if [[ -z "$list" ]]; then
        echo "List is empty"
        return 1
    fi

    # Split the list into an array using commas
    IFS=',' read -r -a list_array <<< "$list"

    # Check if the index is valid
    if [[ $index -ge 0 && $index -lt ${#list_array[@]} ]]; then
        echo "${list_array[$index]}"
    else
        echo "Index $index is out of range"
        return 1
    fi
}

lsrlist_length() {
    local -n list=$1

    # If empty, return null
    if [[ $list == "" ]]; then
        echo "0"
    fi

    # Else, return the amount of entries between commas
    comma_count=$(echo "$list" | grep -o "," | wc -l)
    echo $((comma_count + 1))
}

lsrlist_append() {
    # echo "aaaaaa: $1"
    # echo "aaaaaa: $2"
    local -n list=$1
    local value="$2"

    if [[ "$list" == "" ]]; then
        list="$value"
    else
        list+=",$value"
    fi
}

lsrlist_create() {
    local -n list=$1
    list=""
}