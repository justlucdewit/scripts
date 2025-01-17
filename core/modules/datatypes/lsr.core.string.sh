str_repeat() {
  local char=$1
  local count=$2
  local output=""
  for ((i = 0; i < count; i++)); do
    output+=$char
  done
  echo -en "$output"
}