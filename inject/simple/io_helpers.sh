print_info() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[34m[info] $1\e[0m"  # \e[34m is the color code for blue
}

print_warn() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[33m[warn] $1\e[0m"  # \e[34m is the color code for blue
}

print_normal() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo "$1"
}

print_empty_line() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo ""
}

print_error() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[31m[error] $1\e[0m"  # \e[31m is the color code for red
}

print_debug() {
    SETTINGS_FILE=~/scripts/_settings.yml
    DEBUG=$(yq e '.debug' "$SETTINGS_FILE")
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $DEBUG == false || $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[33m[debug] $1\e[0m"  # \e[33m is the color code for yellow
}

print_success() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -e "\e[32m[success] $1\e[0m"  # \e[32m is the color code for green
}

read_info() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -ne "\e[34m[info] $1\e[0m"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}

read_normal() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -n "$1"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}

read_error() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -ne "\e[31m[error] $1\e[0m"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}

read_debug() {
    SETTINGS_FILE=~/scripts/_settings.yml
    DEBUG=$(yq e '.debug' "$SETTINGS_FILE")
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $DEBUG == false || $SILENT == true ]]; then
        return 0
    fi

    echo -ne "\e[33m[debug] $1\e[0m"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}

read_success() {
    SETTINGS_FILE=~/scripts/_settings.yml
    SILENT=$(yq e '.silent' "$SETTINGS_FILE")
    if [[ $SILENT == true ]]; then
        return 0
    fi

    echo -ne "\e[32m[success] $1\e[0m"
    read -r user_input
    printf -v "$2" "%s" "$user_input"
}