str_repeat() {
  local char=$1
  local count=$2
  local output=""
  for ((i = 0; i < count; i++)); do
    output+=$char
  done
  echo -en "$output"
}

str_empty() {
    local str="$1"
    if [[ "$str" == "" ]]; then
        return 0
    else
        return 1
    fi
}

str_equals() {
    local str1="$1"
    local str2="$2"

    if [[ "$str1" == "$str2" ]]; then
        return 0
    fi

    return 1
}

str_ends_with() {
    local str="$1"
    local value="$2"
    if [[ "$str" == *"$value" ]]; then
        return 0
    else
        return 1
    fi
}

str_starts_with() {
    local str="$1"
    local value="$2"
    if [[ "$str" == "$value"* ]]; then
        return 0
    else
        return 1
    fi
}

str_contains() {
    local str="$1"
    local value="$2"
    if [[ "$str" == *"$value"* ]]; then
        return 0
    else
        return 1
    fi
}
