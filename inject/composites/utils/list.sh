# Composite command
lsrlist() {
    # Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - lsrlist create <listname>"
        echo "  - lsrlist append <listname> <item>"
        echo "  - lsrlist index <listname> <index>"
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
    else
        print_error "Command $command does not exist"
        lsrlist # Re-run for help command
    fi
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