alias notes="notes_main_command"

notes_ensure_dir_exists() {
    mkdir -p "$LSR_NOTES_DIR"
    mkdir -p "$LSR_NOTES_DIR/journal"
}

create_journal_today_if_not_exists() {
    if [[ ! -f "$LSR_NOTES_TODAY_FILE" ]]; then
        {
            echo "# Done: "
            echo "[0,00]      * Total"
            echo ""
            echo "# Todo: "
            echo ""
            echo "# Backlog: "
            echo ""
        } > "$LSR_NOTES_TODAY_FILE"
    fi
}

reconstruct_today() {
    local list_done="$1"
    local list_todo="$2"
    local list_backlog="$3"

    local done_count="$(lsrlist length list_done)"
    local todo_count="$(lsrlist length list_todo)"
    local backlog_count="$(lsrlist length list_backlog)"

    {
        # Inject done items
        echo "# Done: "
        for ((i=0; i<done_count; i++)); do
            lsrlist index list_done "$i"
        done
        echo ""

        # Inject todo items
        echo "# Todo: "
        for ((i=0; i<todo_count; i++)); do
            lsrlist index list_todo "$i"
        done
        echo ""

        # Inject backlog items
        echo "# Backlog: "
        for ((i=0; i<backlog_count; i++)); do
            lsrlist index list_backlog "$i"
        done
        echo ""


    } > "$LSR_NOTES_TODAY_FILE"
}

# Composite command
notes_main_command() {
    notes_ensure_dir_exists
    create_journal_today_if_not_exists
    notes_recalculate
    
    if [ ! "$#" -gt 0 ]; then
        print_normal "usage: "
        print_normal "  - notes today"
        print_normal "  - notes todo <todo>"
        print_normal "  - notes done"
        print_normal "  - notes backlog <todo>"
        print_normal "  - notes todo-del"
        print_normal "  - notes backlog-del"
        print_normal "  - notes edit"
        print_normal "  - notes sync"
        return
    fi

    local command=$1
    shift

    if is_in_list "$command" "today"; then
        notes_today $@
    elif is_in_list "$command" "todo"; then
        notes_add_todo $@
    elif is_in_list "$command" "done"; then
        notes_todo_done $@
    elif is_in_list "$command" "backlog"; then
        notes_add_backlog $@
    elif is_in_list "$command" "todo-del"; then
        notes_delete_todo $@
    elif is_in_list "$command" "backlog-del"; then
        notes_delete_backlog $@
    elif is_in_list "$command" "edit"; then
        notes_edit $@
    elif is_in_list "$command" "sync"; then
        notes_sync $@
    else
        notes_main_command
    fi
}

notes_edit() {
    vim "$LSR_NOTES_TODAY_FILE"
}

notes_recalculate() {
    # Create list for journal reconstruction
    lsrlist create done_items
    lsrlist create todo_items
    lsrlist create backlog_items

    # Get current items
    total_minutes=0
    done_lines=$(awk '/# Done:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        if [[ "$line" == *"* Total"* ]]; then
            continue
        fi
        time=$(echo "$line" | sed 's/^\[\([0-9]*\.[0-9]*\)\].*/\1/')
        if [[ "$time" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
            hours=${BASH_REMATCH[1]}
            minutes=${BASH_REMATCH[2]}

            if [[ "$minutes" -lt "10" ]]; then
                minutes=$((minutes * 10))
            fi

            total_minutes=$((total_minutes + hours * 100 + minutes))
        fi
        lsrlist append done_items "$line"
    done <<< "$done_lines"

    # Loop through lines under "# Todo:"
    todo_lines=$(awk '/# Todo:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append todo_items "$line"
    done <<< "$todo_lines"

    # Loop through lines under "# Backlog:"
    backlog_lines=$(awk '/# Backlog:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append backlog_items "$line"
    done <<< "$backlog_lines"

    # Add the total
    total_hours=$((total_minutes / 100))
    remaining_minutes=$((total_minutes % 100))
    recalculated_total="[$total_hours.$remaining_minutes] * Total"
    lsrlist append done_items "$recalculated_total"

    reconstruct_today "$done_items" "$todo_items" "$backlog_items"
}

notes_todo_done() {
    # Create list for journal reconstruction
    lsrlist create done_items
    lsrlist create todo_items
    lsrlist create backlog_items
    
    # Get current items
    total_minutes=0
    done_lines=$(awk '/# Done:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        if [[ "$line" == *"* Total"* ]]; then
            continue
        fi
        time=$(echo "$line" | sed 's/^\[\([0-9]*\.[0-9]*\)\].*/\1/')
        if [[ "$time" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
            hours=${BASH_REMATCH[1]}
            minutes=${BASH_REMATCH[2]}
            if [[ "$minutes" -lt "10" ]]; then
                minutes=$((minutes * 10))
            fi
            total_minutes=$((total_minutes + hours * 100 + minutes))
        fi
        lsrlist append done_items "$line"
    done <<< "$done_lines"

    # Loop through lines under "# Todo:"
    todo_lines=$(awk '/# Todo:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append todo_items "${line:3}"
    done <<< "$todo_lines"

    # Loop through lines under "# Backlog:"
    backlog_lines=$(awk '/# Backlog:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append backlog_items "$line"
    done <<< "$backlog_lines"

    # Remove selected item
    selectable_list "Select todo to delete:" valueToDelete "$todo_items"
    lsrlist create todo_items_new
    local todo_count=$(lsrlist length todo_items)
    for ((i=0; i<todo_count; i++)); do
        local item_to_add=$(lsrlist index todo_items "$i")

        if [[ ! "$item_to_add" == "$valueToDelete" ]]; then
            lsrlist append todo_items_new " - $item_to_add"
        fi
    done

    # Add item to done_items
    read_normal "Time: " hours
    valueToDelete="[$hours] - $valueToDelete"
    lsrlist append done_items "$valueToDelete"

    # Add the total
    if [[ "$hours" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        hours=${BASH_REMATCH[1]}
        minutes=${BASH_REMATCH[2]}
        if [[ "$minutes" -lt "10" ]]; then
            minutes=$((minutes * 10))
        fi
        total_minutes=$((total_minutes + hours * 100 + minutes))
    fi
    total_hours=$((total_minutes / 100))
    remaining_minutes=$((total_minutes % 100))
    if [[ "$minutes" -lt "10" ]]; then
        minutes=$((minutes * 10))
    fi
    recalculated_total="[$total_hours.$remaining_minutes] * Total"
    lsrlist append done_items "$recalculated_total"

    reconstruct_today "$done_items" "$todo_items_new" "$backlog_items"
}

notes_delete_backlog() {
    # Create list for journal reconstruction
    lsrlist create done_items
    lsrlist create todo_items
    lsrlist create backlog_items
    
    # Get current items
    done_lines=$(awk '/# Done:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append done_items "$line"
    done <<< "$done_lines"

    # Loop through lines under "# Todo:"
    todo_lines=$(awk '/# Todo:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append todo_items "$line"
    done <<< "$todo_lines"

    # Loop through lines under "# Backlog:"
    backlog_lines=$(awk '/# Backlog:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append backlog_items "${line:3}"
    done <<< "$backlog_lines"

    # Remove selected item
    selectable_list "Select backlog to delete:" valueToDelete "$backlog_items"
    lsrlist create backlog_items_new
    local backlog_count=$(lsrlist length backlog_items)
    for ((i=0; i<backlog_count; i++)); do
        local item_to_add=$(lsrlist index backlog_items "$i")

        if [[ ! "$item_to_add" == "$valueToDelete" ]]; then
            lsrlist append backlog_items_new " - $item_to_add"
        fi
    done

    reconstruct_today "$done_items" "$todo_items" "$backlog_items_new"
}

notes_delete_todo() {
    # Create list for journal reconstruction
    lsrlist create done_items
    lsrlist create todo_items
    lsrlist create backlog_items
    
    # Get current items
    done_lines=$(awk '/# Done:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append done_items "$line"
    done <<< "$done_lines"

    # Loop through lines under "# Todo:"
    todo_lines=$(awk '/# Todo:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append todo_items "${line:3}"
    done <<< "$todo_lines"

    # Loop through lines under "# Backlog:"
    backlog_lines=$(awk '/# Backlog:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append backlog_items "$line"
    done <<< "$backlog_lines"

    # Remove selected item
    selectable_list "Select todo to delete:" valueToDelete "$todo_items"
    lsrlist create todo_items_new
    local todo_count=$(lsrlist length todo_items)
    for ((i=0; i<todo_count; i++)); do
        local item_to_add=$(lsrlist index todo_items "$i")

        if [[ ! "$item_to_add" == "$valueToDelete" ]]; then
            lsrlist append todo_items_new " - $item_to_add"
        fi
    done

    reconstruct_today "$done_items" "$todo_items_new" "$backlog_items"
}

notes_add_backlog() {
    local backlog="$@"
    local backlog_entry=" - $backlog"
    if [ ! "$#" -gt 0 ]; then
        print_normal "usage: notes backlog <todo>"
    fi

    # Create list for journal reconstruction
    lsrlist create done_items
    lsrlist create todo_items
    lsrlist create backlog_items
    
    # Get current items
    done_lines=$(awk '/# Done:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append done_items "$line"
    done <<< "$done_lines"

    # Loop through lines under "# Todo:"
    todo_lines=$(awk '/# Todo:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append todo_items "$line"
    done <<< "$todo_lines"

    # Loop through lines under "# Backlog:"
    backlog_lines=$(awk '/# Backlog:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append backlog_items "$line"
    done <<< "$backlog_lines"

    # Add todo
    lsrlist append backlog_items "$backlog_entry"

    # Reconstruct
    reconstruct_today "$done_items" "$todo_items" "$backlog_items"
}

notes_add_todo() {
    local todo="$@"
    local todo_entry=" - $todo"
    if [ ! "$#" -gt 0 ]; then
        print_normal "usage: notes todo <todo>"
    fi

    # Create list for journal reconstruction
    lsrlist create done_items
    lsrlist create todo_items
    lsrlist create backlog_items
    
    # Get current items
    done_lines=$(awk '/# Done:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append done_items "$line"
    done <<< "$done_lines"

    # Loop through lines under "# Todo:"
    todo_lines=$(awk '/# Todo:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append todo_items "$line"
    done <<< "$todo_lines"

    # Loop through lines under "# Backlog:"
    backlog_lines=$(awk '/# Backlog:/{flag=1;next}/^#/{flag=0}flag' "$LSR_NOTES_TODAY_FILE")
    while IFS= read -r line; do
        lsrlist append backlog_items "$line"
    done <<< "$backlog_lines"

    # Add todo
    lsrlist append todo_items "$todo_entry"

    # Reconstruct
    reconstruct_today "$done_items" "$todo_items" "$backlog_items"
}

notes_sync() {
    # Make sure locally we are up to date
    git -C "$LSR_NOTES_DIR" pull origin master

    # Now push changes if there are any
    # if [[ -n "$(git -C "$LSR_NOTES_DIR" status --porcelain)" ]]; then
    #     git -C "$LSR_NOTES_DIR" add .
    #     git -C "$LSR_NOTES_DIR" commit -m 'Updated notes'
    #     git -C "$LSR_NOTES_DIR" push origin master 
    # fi
}

notes_today() {
    cat "$LSR_NOTES_TODAY_FILE"
}