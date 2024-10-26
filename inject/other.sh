LIGHT_GREEN='\033[1;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Update PS1 to include the Git branch if in a Git repo
get_project_branch_label() {
    local current_project=$(get_current_project_label)
    local current_branch=$(parse_git_branch)

    if [[ -n $current_project && -n $current_branch ]]; then
        echo -e " ($RED$current_project$RESET: $current_branch)"
    else
        if [[ -n $current_project ]]; then
            echo -e " ($RED$current_project$RESET)"
        fi

        if [[ -n $current_branch ]]; then
            echo -e " ($current_branch)"
        fi
    fi
}

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\]$(get_project_branch_label)\$ '

get_dir_part() {
    current_project=$(cproj)
    if [[ -n $current_project ]]; then
        echo " 🔧 $current_project "
    else
        current_dir=$(pwd | sed "s|^$HOME|~|")
        echo " 📝 $current_dir "
    fi
}

get_git_part() {
    local current_branch=$(parse_git_branch)

    if [[ -n $current_branch ]]; then
        echo -e " 🔗 $current_branch "
    else
        echo ""
    fi
}

set_powerline_ps1() {
    local isRoot=0  # Default to not root
    if [[ ${EUID} -eq 0 ]]; then
        isRoot=1  # Set to 1 if running as root
    fi

    PS1=''

    local user_part
    local dir_part
    local git_part

    local black="0;0;0"
    local white="255;255;255"
    local red="255;0;0"
    local green="42;135;57"
    local blue="0;135;175"
    local yellow="179;127;55"

    # Define colors
    local blue_bg="\[\033[48;2;${blue}m\]"   # Blue Background
    local red_bg="\[\033[48;2;${red}m\]"     # Red Background
    local yellow_bg="\[\033[48;2;${yellow}m\]" # Darker Yellow Background
    local green_bg="\[\033[48;2;${green}m\]"    # Green Background
    local black_bg="\[\033[48;2;${black}m\]"    # Black Background

    local yellow_fg="\[\033[38;2;${yellow}m\]" # White Text
    local green_fg="\[\033[38;2;${green}m\]"       # Green Text
    local red_fg="\[\033[38;2;${red}m\]"       # Red Text
    local blue_fg="\[\033[38;2;${blue}m\]"       # Red Text
    local white_fg="\[\033[38;2;${white}m\]" # White Text
    local black_fg="\[\033[38;2;${black}m\]"       # Black Text

    if [[ $isRoot ]]; then
        user_part="${blue_bg}${white_fg} \u@\h ${blue_fg}${yellow_bg}"  # Blue arrow with yellow background
    else
        user_part="${red_bg}${white_fg} \u@\h ${red_fg}${yellow_bg}"  # Red arrow with yellow background
    fi

    # Directory part with darker yellow background and black text
    dir_part="${white_fg}${yellow_bg}\$(get_dir_part)${green_bg}${yellow_fg}"  # Yellow arrow with green background
    dir_ending_part="${white_fg}${yellow_bg}\$(get_dir_part)${black_bg}${yellow_fg}"

    # Git part with green background and white text
    git_part="${white_fg}${green_bg}\$(get_git_part)${green_fg}${black_bg}"  # Green arrow with blue background

    if [[ -z $(get_git_part) ]]; then
        PS1="${user_part}${dir_ending_part}\[\033[00m\] "
    else
        PS1="${user_part}${dir_part}${git_part}\[\033[00m\] "
    fi
}

set_powerline_ps1
PROMPT_COMMAND=set_powerline_ps1

lsrdebug() {
    local SETTINGS_FILE=~/scripts/_settings.yml
    local current_value=$(yq e '.debug' "$SETTINGS_FILE")

    if [[ -n "$1" ]]; then
        # If an argument is passed, set the value based on it
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".debug = $1" "$SETTINGS_FILE"
            print_info "Debug mode set to $1."
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
        # No argument passed, toggle the current value
        if [[ "$current_value" == "true" ]]; then
            yq e -i '.debug = false' "$SETTINGS_FILE"
            print_info "Debug mode disabled."
        else
            yq e -i '.debug = true' "$SETTINGS_FILE"
            print_info "Debug mode enabled."
        fi
    fi
}

lsrsilence() {
    local SETTINGS_FILE=~/scripts/_settings.yml
    local current_value=$(yq e '.silent' "$SETTINGS_FILE")

    if [[ -n "$1" ]]; then
        # If an argument is passed, set the value based on it
        if [[ "$1" == "true" || "$1" == "false" ]]; then
            yq e -i ".silent = $1" "$SETTINGS_FILE"
        else
            print_error "Invalid argument. Use 'true' or 'false'."
        fi
    else
        # No argument passed, toggle the current value
        if [[ "$current_value" == "true" ]]; then
            yq e -i '.silent = false' "$SETTINGS_FILE"
        else
            yq e -i '.silent = true' "$SETTINGS_FILE"
        fi
    fi
}

now() {
    local local_settings_file="$HOME/scripts/local_data/local_settings.yml"
    local local_settings_dir="$(dirname "$local_settings_file")"
    local api_key
    local lat
    local lon
    local unconfigured=false

    # Ensure the local_settings directory exists
    mkdir -p "$local_settings_dir"

    # Create an empty local_settings.yml if it doesn't exist
    if [[ ! -f "$local_settings_file" ]]; then
        touch "$local_settings_file"
    fi

    # Function to retrieve weather settings from YAML
    get_weather_settings() {
        # Use yq to extract values from the YAML file
        api_key=$(yq e '.weatherapi.api_key // ""' "$local_settings_file")
        lat=$(yq e '.weatherapi.lat // ""' "$local_settings_file")
        lon=$(yq e '.weatherapi.lon // ""' "$local_settings_file")
        
        # Check if the weatherapi section exists, if not create it
        if [[ -z "$api_key" ]]; then
            yq e -i '.weatherapi.api_key = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.api_key' "$local_settings_file")
            unconfigured=true
        fi

        if [[ -z "$lat" ]]; then
            yq e -i '.weatherapi.lat = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.lat' "$local_settings_file")
            unconfigured=true
        fi

        if [[ -z "$lon" ]]; then
            yq e -i '.weatherapi.lon = null' "$local_settings_file"
            localsettings_reformat
            api_key=$(yq e '.weatherapi.lon' "$local_settings_file")
            unconfigured=true
        fi

        # Trim any whitespace or quotes from the extracted values
        api_key=$(echo "$api_key" | xargs)
        lat=$(echo "$lat" | xargs)
        lon=$(echo "$lon" | xargs)
    }

    # Get current time in "mm:hh dd/mm/yyyy" format
    local current_time=$(date +"%H:%M %d/%m/%Y")

    # Fetch weather data using the API settings
    get_weather_settings

    if [[ "$unconfigured" == "true" ]]; then
        print_error "Weather API is not configured in settings_data. Configure it with https://openweathermap.org/api\n"
        return 1
    fi
    
    # Call the weather API (OpenWeatherMap in this case)
    local weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$api_key&units=metric")

    # Check if the API returned a valid result
    if [[ -z "$weather_data" ]] || [[ "$(echo "$weather_data" | jq '.cod')" != "200" ]]; then
        print_error "Unable to fetch weather data\n"
        return 1
    fi

    # Parse the weather data using `jq`
    local temp_now=$(echo "$weather_data" | jq '.main.temp')
    local temp_min=$(echo "$weather_data" | jq '.main.temp_min')
    local temp_max=$(echo "$weather_data" | jq '.main.temp_max')
    local humidity=$(echo "$weather_data" | jq '.main.humidity')
    local wind_speed=$(echo "$weather_data" | jq '.wind.speed')
    local weather_condition=$(echo "$weather_data" | jq -r '.weather[0].description')
    local city=$(echo "$weather_data" | jq -r '.name')

    # Define ANSI color codes
    local bold="\033[1m"
    local green="\033[32m"
    local blue="\033[34m"
    local cyan="\033[36m"
    local reset="\033[0m"
    local red="\033[0;31m"
    local yellow='\033[0;33m'

    # Print formatted and colored output
    color_value() {
        local value="$1"
        local low_threshold="$2"
        local mid_threshold="$3"
        local high_threshold="$4"
        local colored_str

        # Use bc for comparisons
        if (( $(echo "$value < $low_threshold" | bc -l) )); then
            colored_str="${blue}${value}${reset}"
        elif (( $(echo "$value >= $low_threshold" | bc -l) && $(echo "$value < $mid_threshold" | bc -l) )); then
            colored_str="${green}${value}${reset}"
        elif (( $(echo "$value >= $mid_threshold" | bc -l) && $(echo "$value < $high_threshold" | bc -l) )); then
            colored_str="${yellow}${value}${reset}"
        else
            colored_str="${red}${value}${reset}"
        fi
        echo "$colored_str"
    }
    
    local temp_now_str=$(color_value "$temp_now" 10 20 25)
    local temp_min_str=$(color_value "$temp_min" 10 20 25)
    local temp_max_str=$(color_value "$temp_max" 10 20 25)
    local wind_speed_str=$(color_value "$wind_speed" 2 5 10)

    echo -e "${bold}${green}Now in $city:${reset}"
    echo -e "${cyan}$current_time${reset}"
    echo -e "Temperature: ${temp_now_str}°C (${temp_min_str}°C - ${temp_max_str}°C)"
    echo -e "Condition: ${weather_condition} (${wind_speed_str} m/s)"
    print_empty_line
}

lhelp() {
    local lhelp_file="$HOME/scripts/lhelp.txt"
    
    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line == \#* ]]; then
            printf "$RED%s$RESET\n" "$line"
        else
            printf "%s\n" "$line"
        fi
        
    done < "$lhelp_file"

    print_empty_line
}

# Ensure tmux is running
if [ -z "$TMUX" ]; then
    tmux
fi