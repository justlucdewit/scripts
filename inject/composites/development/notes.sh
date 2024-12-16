alias notes="notes_main_command"

# Helper function to make sure the needed notes directories exists
notes_ensure_dir_exists() {
    mkdir -p "$LSR_NOTES_DIR"
    mkdir -p "$LSR_NOTES_DIR/journal"
}

# Helper function to start a journal entry of a specific day
start_journal_of_day() {
    local day="$1"
    local month="$2"
    local year="$3"
    local journal_file="$LSR_NOTES_DIR/journal/$year-$month/$year-$month-$day.md"
    local journal_dir="$(dirname $journal_file)"

    if [[ ! -f "$journal_file" ]]; then
        mkdir -p "$journal_dir"
        {
            echo "# Done: "
            echo ""
            echo "# Todo: "
            echo ""
            echo "# Backlog: "
            echo ""
        } > "$journal_file"
    fi
}

# Helper function to start a journal entry of today
create_journal_today_if_not_exists() {
    start_journal_of_day $LSR_DAY $LSR_MONTH $LSR_YEAR
}

# Composite command
notes_main_command() {
    notes_ensure_dir_exists
    create_journal_today_if_not_exists

    composite_define_command "notes"
    composite_define_subcommand "today"
    composite_define_subcommand "parse"
    composite_define_subcommand "make" "[day month year]"
    composite_handle_subcommand $@
}

notes_parse() {
    local given_day="$1"
    local given_month="$2"
    local given_year="$3"

    # Get the notes content
    local daily_note_file="$LSR_NOTES_DIR/journal/$given_year-$given_month/$given_year-$given_month-$given_day.md"
    local daily_note_content=$(cat "$daily_note_file")
    # echo "$daily_note_content"
    
    # Loop over the notes content line by line
    local mode="Done"
    local tasks="["
    while IFS= read -r line; do
        if [[ "$line" == "# Done"* ]]; then
            mode="Done"
        fi

        if [[ "$line" == "# Todo"* ]]; then
            mode="Todo"
        fi

        if [[ "$line" == "# Backlog"* ]]; then
            mode="Backlog"
        fi

        if [[ "$line" == "- "* ]]; then
            # Parse the individual task line
            local task_description="${line%% (*}"
            task_description="${task_description:2}"
            local task_duration=$(echo "$line" | awk -F'\\(|\\)' '{if (NF > 1) print $2; else print ""}')
            
            # Create the object
            obj create currentTask
            obj set currentTask description "$task_description"
            obj set currentTask type "$mode"

            if [[ -n "$task_duration" ]]; then
                obj set currentTask duration "$task_duration"
            fi

            if [[ "$tasks" == "[" ]]; then
                tasks+="$currentTask"
            else
                tasks+=",$currentTask"
            fi
        fi
        # echo "Processing: $line"
    done <<< "$daily_note_content"

    tasks+="]"
    echo "$tasks"

    reset_ifs
}

notes_make() {
    local day="$1"
    local month="$2"
    local year="$3"

    if [[ "$day" == "" ]]; then
        day="$LSR_DAY"
    fi

    if [[ "$month" == "" ]]; then
        month="$LSR_MONTH"
    fi

    if [[ "$year" == "" ]]; then
        year="$LSR_YEAR"
    fi

    start_journal_of_day $day $month $year
}

notes_today() {
    cat "$LSR_NOTES_TODAY_FILE"
}