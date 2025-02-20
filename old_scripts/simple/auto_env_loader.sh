load_env_file() {
    local env_file="$1"

    # Check if the file exists
    if [[ ! -f "$env_file" ]]; then
        print_error ".env file '$env_file' not found."
        return 1
    fi

    # Export each line in the .env file that matches the 'key=value' format
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        # Ignore empty lines and comments
        if [[ -n "$key" && ! "$key" =~ ^# ]]; then
            # Remove surrounding quotes from value if present
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"

            export "$key=$value"
        fi
    done < "$env_file"
}

auto_load_env_files() {
    load_env_file "$HOME/scripts/global.env" &> /dev/null
    load_env_file "$HOME/global.env" &> /dev/null
}