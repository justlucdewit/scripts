# single-select
# multi-select
# single-input
# multi-input

LSR_WINDOW_MENU_COUNT=0
LSR_WINDOW_MENU_TITLES=()

calculate-window-values() {
    LSR_TERM_WIDTH=$(tput cols)
    LSR_TERM_HEIGHT=$(tput lines)
}

render_window() {
    # Reset all values
    LSR_WINDOW_MENU_COUNT=0

    # Recalculate window
    calculate-window-values

    local title="$1"
    local title_length="${#title}"

    window_outer_width=$((LSR_TERM_WIDTH))
    window_inner_width=$((LSR_TERM_WIDTH - 2))
    window_outer_height=$((LSR_TERM_HEIGHT))
    window_inner_height=$((LSR_TERM_HEIGHT - 2))

    (( title_length -= 4 ))
    clear

    echo "┌─ $title $(str_repeat ─ $((window_inner_width - 7 - title_length)))┐"
    echo "$(str_repeat "│$(str_repeat " " $((window_inner_width)))│\n" $((window_inner_height)))"
    echo -n "└$(str_repeat "─" $((window_inner_width)))┘"
}

register_window_menu() {
    local sub_menus="$1"
    (( LSR_WINDOW_MENU_COUNT++ ))
}

alias window="window_main_command"

window_main_command() {
    # Define subcommands
    composite_define_command "window"

    composite_define_subcommand "create"
    composite_define_subcommand_parameter "create" "--title" "Sets the title for window"
    composite_define_subcommand_parameter "create" "--border" "Sets the borderstyle, can be either lines, invisible, or none"
    composite_define_subcommand_parameter "create" "--submenu-list" "Comma seperated list of submenu titles"

    # Describe subcommands
    composite_define_subcommand_description "create" "Create a terminal-ui window application"

    composite_handle_subcommand $@
}

window_create() {
    # tput smcup

    register_window_menu "a,b,c"
    register_window_menu "d,e,f"
    register_window_menu "hello"

    # while true; do
    #     clear

    #     render_window "Bash Terminal UI Test"
        
    #     # Get a keypress
    #     read -n 1 -s key

    #     if [[ "$key" == "q" ]]; then
    #         echo "Exiting the loop."
    #         break
    #     fi
    # done
    
    # tput rmcup
    echo "test => $LSR_COMPOSITE_FLAGS"
}