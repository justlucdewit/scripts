# Define a list of banned patterns
banned_patterns=(
    "*.exe"
    "*/node_modules/*"
    "*/vendor/*"
    "*.lock"
    "*/.git/*"
    "*.log"
    "*/storage/framework/views/*"
    "*/public/*"
    "*/package-lock.json"
)

RED='\033[0;31m'
RESET='\033[0m'

# Function to check if a file matches any banned pattern
is_banned() {
  local file="$1"
  for pattern in "${banned_patterns[@]}"; do
    # Use double brackets with globbing to allow pattern matching
    if [[ "$file" == $pattern ]]; then
      return 0 # File matches a banned pattern
    fi
  done
  return 1 # File does not match any banned pattern
}

cfind() {
    local query=$1

    if [[ -z $query ]]; then
        echo "Usage: cfind <query string>"
        return 1
    fi

    # Escape special characters in the query for awk
    escaped_query=$(echo "$query" | sed 's/[.*+?[^$()|{}]/\\&/g')

    # Loop through all of the files in the current directory and subdirectories
    find . -type f | while read -r filepath; do
        if ! is_banned "$filepath"; then
            local filename=$(basename "$filepath")
            
            # Use awk to search for the escaped pattern and capture line and column info
            awk -v pattern="$escaped_query" -v fname="$filepath" '
                {
                    # Remove leading whitespace
                    gsub(/^[ \t]+/, "");
                    if ($0 ~ pattern) {
                        # Print filename, line number, column number, and trimmed content
                        printf "\033[0;31m%s:%d:%d\033[0m: %s\n", fname, NR, index($0, pattern), $0
                    }
                }
            ' "$filepath"
        fi
    done
}
