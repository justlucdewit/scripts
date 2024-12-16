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
    composite_define_subcommand "make" "[day month year]"
    composite_handle_subcommand $@
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