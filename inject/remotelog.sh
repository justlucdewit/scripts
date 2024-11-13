#!/bin/bash

start_remote_log_catcher_server() {
    PORT="$1"
    URL="$2"
    if [[ -z $1 ]]; then
        PORT=43872
    fi

    # Start the server
    echo "Server running on port $URL, waiting for requests..."

    # Infinite loop to keep the server running
    while true; do
        # Use nc to listen and capture the output into a temporary file
        request=$(nc -l -p "$PORT" -w 1)  # -w 5 means wait for up to 5 seconds for data

        # If no data is received, continue to the next loop
        if [ -z "$request" ]; then
            continue
        fi

        # Extract the body of the request (everything after the blank line)
        body=$(echo "$request" | sed -n '/^\r$/,$p' | tail -n +2)

        # Log the raw body to the console
        print_info "$request"
    done
}

locallog() {
    # Set default port if not provided
    port="$1"
    if [[ -z $1 ]]; then
        port=58473
    fi

    # Start the remote log catcher server
    start_remote_log_catcher_server $port "https://localhost:$port"
}

remotelog() {
    > $LOG_FILE
    local LOG_FILE='./ngrok.log'

    for pid in $(pgrep ngrok); do
        kill -9 $pid
    done

    if ! command -v "ngrok" &> /dev/null; then
        print_error "ngrok must be installed for remotelog. Please install and run ngrok config add-authtoken <token>"
    fi

    # Check if ngrok is already running and kill it
    pgrep ngrok > /dev/null
    if [ $? -eq 0 ]; then
        print_info "ngrok was already running, killing other instance... you can only have one ngrok/remotelog instance running."
        pkill ngrok  # Kill any running ngrok processes
        sleep 1  # Give a moment for the processes to terminate
    fi

    # Set default port if not provided
    port="$1"
    if [[ -z $1 ]]; then
        port=58473
    fi

    print_info "Initializing server..."

    # Start ngrok in the background and redirect both stdout and stderr to the log file
    ngrok http $port --log $LOG_FILE &
    NGROK_PID=$!

    # Wait for ngrok to generate the URL by checking the log file
    while ! grep -q 'https://[a-z0-9\-]*.ngrok-free.app' $LOG_FILE; do
        sleep 1  # Wait until the URL is available in the log
    done

    # Extract the ngrok URL from the log file
    NGROK_URL=$(grep 'https://[a-z0-9\-]*.ngrok-free.app' $LOG_FILE | awk -F"url=" '{print $2}' | awk '{print $1}')

    # Print the ngrok URL
    echo "Your ngrok URL is: $NGROK_URL"

    # Start the remote log catcher server
    start_remote_log_catcher_server $port $NGROK_URL
}

