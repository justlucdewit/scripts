jjjjLIGHT_GREEN='\033[1;32m'
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

    if command_exists "profile"; then
        local current_profile="$(profile current)"
    fi

    if [[ $isRoot ]]; then
        user_part="${blue_bg}${white_fg} \u@\h - $current_profile ${blue_fg}${yellow_bg}"  # Blue arrow with yellow background
    else
        user_part="${red_bg}${white_fg} \u@\h - $current_profile ${red_fg}${yellow_bg}"  # Red arrow with yellow background
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

do_before_prompt() {
    set_powerline_ps1
    localsettings_reformat
}

set_powerline_ps1
localsettings_reformat
PROMPT_COMMAND=do_before_prompt

packages() {
    if [[ -f "./package.json" ]]; then
        dependencies=$(jq '.dependencies' package.json)
        if [[ "$dependencies" != "null" && "$dependencies" != "{}" && -n "$dependencies" ]]; then
            echo "Npm packages:"
            jq -r '.dependencies | to_entries | .[] | " - " + .key + " -> " + .value' package.json
            echo ""
        fi
    fi

    if [[ -f "./composer.json" ]]; then
        dependencies=$(jq '.require' composer.json)
        if [[ "$dependencies" != "null" && "$dependencies" != "{}" && -n "$dependencies" ]]; then
            echo "Composer packages:"
            jq -r '.require | to_entries | .[] | " - " + .key + " -> " + .value' composer.json
            echo ""
        fi

        # dev_dependencies=$(jq '.require-dev' composer.json)
        # if [[ "$dev_dependencies" != "null" && "$dev_dependencies" != "{}" && -n "$dev_dependencies" ]]; then
        #     echo "Composer packages (dev):"
        #     jq -r '.require-dev | to_entries | .[] | " - " + .key + " -> " + .value' composer.json
        #     echo ""
        # fi
    fi
}

select_scripts() {
    scripts_output=$(scripts)
    scripts_list=$(echo "$scripts_output" | grep '^ - ' | awk '{sub(/^ - /, ""); if (NR > 1) printf ","; printf "%s", $0} END {print ""}')
    
    local value=""
    selectable_list "Select a script" value "$scripts_list"
    $value
}

# Finds scripts to fall back on, in either the current dir, or the ./scripts/ or the ./_lsr_scripts dir.
# If the script name starts with an underscore, it is hidden and thus not listed nor callable
# - bash scripts
# - python scripts
# - nodejs scripts
scripts() {
    if [[ $(find . -maxdepth 1 -wholename "./*.sh" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.sh" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.sh" -print -quit)) ]]; then
        echo "Bash scripts:"
    fi
    for file in ./*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*" && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    for file in ./scripts/*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    for file in ./_lsr_scripts/*.sh; do
        filename="${file##*/}"      # Remove the ./ prefix
        basename="${filename%.sh}"  # Remove the .sh suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.sh" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.sh" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.sh" -print -quit)) ]]; then
        echo ""
    fi

    if [[ $(find . -maxdepth 1 -wholename "./*.py" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.py" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.py" -print -quit)) ]]; then
        echo "Python scripts:"
    fi
    for file in ./*.py; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.py}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo "- $basename"
        fi
    done
    for file in ./scripts/*.py; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.py}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.py" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*.py" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.py" -print -quit)) ]]; then
        echo ""
    fi

    if [[ $(find . -maxdepth 1 -wholename "./*.js" -print -quit) || ( -d ./scripts && $(find ./scripts -wholename "*js" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.js" -print -quit)) ]]; then
        echo "Node scripts:"
    fi
    for file in ./*.js; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.js}"  # Remove the .js suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo "- $basename"
        fi
    done
    for file in ./scripts/*.js; do
        filename="${file##*/}"      # Remove the ./scripts/ prefix
        basename="${filename%.js}"  # Remove the .py suffix

        if [[ "$basename" != "*"  && $basename != _* ]]; then
            echo " - $basename"
        fi
    done
    if [[ $(find . -maxdepth 1 -wholename "./*.js" -print -quit)  || ( -d ./scripts && $(find ./scripts -wholename "*.js" -print -quit) ) || ( -d ./_lsr_scripts && $(find ./_lsr_scripts -wholename "*.js" -print -quit)) ]]; then
        echo ""
    fi

    if [[ -f "./package.json" ]]; then
        scripts=$(jq '.scripts' package.json)
        if [[ "$scripts" != "null" && "$scripts" != "{}" && -n "$scripts" ]]; then
            echo "Npm scripts:"
            jq -r ".scripts | \" - \" + keys[]" ./package.json
            echo ""
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



# Ensure tmux is running
setup_tmux_config
tmux source-file ~/.tmux.conf
if [ -z "$TMUX" ]; then
    tmux
fi

alias tu="time_until"
time_until() {
    # Define target times
    target0="8:30:00"
    target1="12:30:00"
    target2="17:00:00"
    
    # Get the current time in seconds since midnight
    local now=$(date +%s)
    
    # Get today's date and convert target times to seconds since midnight
    today=$(date +%Y-%m-%d)
    target0_sec=$(date -d "$today $target0" +%s)
    target1_sec=$(date -d "$today $target1" +%s)
    target2_sec=$(date -d "$today $target2" +%s)

    # Calculate seconds remaining for each target
    passed0=$((now - target0_sec)) # TODO: base this on the first terminal login of the day
    remaining1=$((target1_sec - now))
    remaining2=$((target2_sec - now))

    # Function to convert seconds to hh:mm:ss
    format_time() {
        local seconds=$1
        printf "%02d:%02d:%02d\n" $((seconds/3600)) $(( (seconds%3600)/60 )) $((seconds%60))
    }

    if [ $passed0 -gt 0 ]; then
        echo "Time passed at work: $(format_time $passed0)"
    else
        echo "Work has not started yet"
    fi

    # Display results for both target times
    if [ $remaining1 -gt 0 ]; then
        echo "Time left until break: $(format_time $remaining1)"
    else
        echo "Break time has already passed."
    fi
    
    if [ $remaining2 -gt 0 ]; then
        echo "Time left until End of day: $(format_time $remaining2)"
    else
        echo "End of day has already passed today."
    fi
}

exp() {
    local initial_dir="$(pwd)"
    eval "flags=($(composite_help_get_flags "$@"))"

    local go=false
    if composite_help_contains_flag go "${flags[@]}"; then
        go=true
    fi

    while true; do
        lsrlist create dir_items
        lsrlist append dir_items "."
        lsrlist append dir_items ".."

        # Add folders
        for item in *; do
            if [ -d "$item" ]; then
                lsrlist append dir_items "/$item/"
            fi
        done

        # Add files
        for item in *; do
            if [ -f "$item" ]; then
                lsrlist append dir_items "$item"
            fi
        done
        
        selectable_list "$(pwd)" value "$dir_items"

        if [[ "$value" == "." ]]; then
            break;
        fi

        if [[ "$value" == ".." ]]; then
            cd ..;
        fi

        if [[ -f "./$value" ]]; then
            cat "./$value"
            echo ""
            break
        fi

        cd ".$value"
    done
    
    if [[ $go != true ]]; then
        cd "$initial_dir"
    fi
}

# For project composite
# - everything in proj.sh
# - 