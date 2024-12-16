# Composite command
lsrlist() {
    composite_define_command "lsrlist"
    composite_define_subcommand "create" "<listname>"
    composite_define_subcommand "append" "<listname> <item>"
    composite_define_subcommand "index" "<listname> <index>"
    composite_define_subcommand "length" "<listname> <index>"
    composite_handle_subcommand $@
}

lsrlist_index() {
    local -n list=$1
    local index=$2

    # Retrieve and echo the item at the specified index
    echo "$list" | jq -r ".[$index]"
}

lsrlist_length() {
    local -n list=$1

    # Get the length of the array
    echo "$list" | jq '. | length'
}

lsrlist_append() {
    local -n list=$1
    local value="$2"

    echo "=> $value"

    list=$(echo "$list" | jq -c --arg value "$value" ". += [\"$value\"]")
}

lsrlist_create() {
    local -n list=$1
    list="[]"
}