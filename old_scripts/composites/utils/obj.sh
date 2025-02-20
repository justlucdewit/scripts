alias obj="obj_main_command"

obj_main_command() {
	# Help command
    if [ ! "$#" -gt 0 ]; then
        echo "usage: "
        echo "  - obj create"
        echo "  - obj set"
        echo "  - obj get"
        return 0
    fi

    local command=$1
    shift

    if is_in_list "$command" "create"; then
        obj_create "$@"
    elif is_in_list "$command" "set"; then
        obj_set "$@"
    elif is_in_list "$command" "get"; then
        obj_get "$@"
    else
    	obj_main_command
    fi
}

obj_create() {
	local -n object=$1
    object="{}"
}

obj_set() {
	local -n object=$1
	local variable_name="$2"
	local value="$3"
    
    object=$(echo "$object" | jq -c ".\"$variable_name\"=\"$value\"")
}

obj_get() {
	local -n object=$1
	local variable_name="$2"

	echo "$object" | jq -r ".\"$variable_name\""
}