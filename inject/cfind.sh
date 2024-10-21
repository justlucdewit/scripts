search() {
    # Initialize variables for exclusions
    exclude_files=()
    exclude_dirs=()

    # Parse arguments
    while [[ "$1" == -* ]]; do
        case "$1" in
            --exclude=*)
                exclude_files+=("${1#--exclude=}")
                shift
                ;;
            --exclude-dir=*)
                exclude_dirs+=("${1#--exclude-dir=}")
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # The last argument should be the search term
    local search_term="$1"
    
    # Check if the search term is provided
    if [[ -z "$search_term" ]]; then
        echo "Usage: search [--exclude=file] [--exclude-dir=dir] search_term"
        return 1
    fi

    # Construct the find command
    local find_command="find . -type f"

    # Add the exclude file conditions if provided
    for file in "${exclude_files[@]}"; do
        find_command+=" ! -path './$file'"
    done

    # Add the exclude directory conditions if provided
    for dir in "${exclude_dirs[@]}"; do
        find_command+=" ! -path './$dir/*'"
    done

    # Execute the find command with grep, ignoring binary files
    eval "$find_command -exec grep -Hn --color=auto --binary-files=without-match '$search_term' {} +" | awk -F: '{for(i=2;i<=NF;i++) printf "%s:%s:%s\n", $1, $2, $i}'
}

cfind() {
    # Usage: cfind [OPTIONS] <search_term>
    
    local exclude_dirs=()
    local exclude_files=() # Array for specific files to exclude
    local limit_results=0
    local search_term=""
    local no_build=false
    local result_count=0
    local search_results=""
    local current_dir_name=$(basename "$PWD")

    # Hardcoded build directories to exclude when --no-build is used
    local build_dirs=("build" "dist" "node_modules" "out" "target" ".git" "vendor")
    local build_files=("public/js/app.js" "composer.lock") # Add specific files here

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --no-build) no_build=true ;;                               # Exclude hardcoded build directories
            -e|--exclude) shift; exclude_dirs+=("--exclude-dir=$1") ;; # Exclude specific directories
            -f|--exclude-file) shift; exclude_files+=("$1") ;;        # Exclude specific files
            -l|--limit) shift; limit_results=$1 ;;                     # Limit number of results
            -t|--type) shift; filetypes="*.$1" ;;                      # Search specific file types
            *)
                if [[ -z "$search_term" ]]; then
                    search_term="$1"  # Assign the search term
                fi
                ;;
        esac
        shift
    done

    # Ensure search term is provided
    if [[ -z "$search_term" ]]; then
        echo "Usage: cfind [OPTIONS] <search_term>"
        echo "Options:"
        echo "  --no-build           Exclude build directories (e.g., 'build', 'node_modules', 'dist', 'out', 'vendor')"
        echo "  -e, --exclude <dir>  Exclude specific directory"
        echo "  -f, --exclude-file <file>  Exclude specific file"
        echo "  -l, --limit <n>      Limit to first n results"
        echo "  -t, --type <ext>     Search specific file types (e.g., 'py', 'js', 'cpp')"
        return 1
    fi

    # Automatically exclude hardcoded build directories and files if --no-build is used
    if $no_build; then
        for dir in "${build_dirs[@]}"; do
            exclude_dirs+=("--exclude-dir=$dir")
        done
        for file in "${build_files[@]}"; do
            exclude_files+=("--exclude=$file")
        done
    fi

    # Escape the search term to handle special characters
    local escaped_search_term=$(printf '%s\n' "$search_term" | sed 's/[.*+?[^$()|{}]/\\&/g')

    # Build the grep command with the appropriate arguments
    local grep_cmd="search"

    # Add the exclude directories
    if [[ ${#exclude_dirs[@]} -gt 0 ]]; then
        grep_cmd+=" ${exclude_dirs[@]}"
    fi

    # Add the exclude files (without the extra --exclude= prefix)
    if [[ ${#exclude_files[@]} -gt 0 ]]; then
        for file in "${exclude_files[@]}"; do
            grep_cmd+=" $file"
        done
    fi

    # Include the search term and directory to search
    grep_cmd+=" \"$escaped_search_term\""

    # Apply result limit if specified
    if [[ "$limit_results" -gt 0 ]]; then
        grep_cmd="$grep_cmd | head -n $limit_results"
    fi

    echo $grep_cmd
    # return

    # Execute the grep command and capture the results
    search_results=$(eval $grep_cmd)

    # Count the number of results
    result_count=$(echo "$search_results" | grep -c "^")

    # Determine box width based on the longest line (adjust for dynamic sizing)
    local max_line="Search results for project: $current_dir_name"
    local second_line="Query: $search_term"
    local third_line="Result count: $result_count"
    local longest_line=$(( $(echo "$max_line" | wc -c) + 4 ))

    # Adjust the width of the box based on the longest line
    [[ $(echo "$second_line" | wc -c) -gt "$longest_line" ]] && longest_line=$(( $(echo "$second_line" | wc -c) + 4 ))
    [[ $(echo "$third_line" | wc -c) -gt "$longest_line" ]] && longest_line=$(( $(echo "$third_line" | wc -c) + 4 ))

    # Print Unicode ASCII box with search summary
    printf "┌%s┐\n" "$(printf '─%.0s' $(seq 1 $((longest_line - 3))))" &&
    printf "│ Search results for project: %-*s │\n" $((longest_line - 33)) "$current_dir_name" &&
    printf "│ Query: %-*s │\n" $((longest_line - 12)) "$search_term" &&
    printf "│ Result count: %-*d │\n" $((longest_line - 19)) "$result_count" &&
    printf "└%s┘\n" "$(printf '─%.0s' $(seq 1 $((longest_line - 3))))"

    # Print results without highlighting and trim spaces
    if [[ $result_count -gt 0 ]]; then
        echo "$search_results" | sed -E 's/^\s*//; s/\s*$//; s/:([0-9]+):/:\1: /' # Trim spaces and format output
    else
        echo "No results found."
    fi
}