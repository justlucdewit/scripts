#!/bin/bash

format_number_with_spaces() {
    # Input Validation
    if [[ -z "$1" ]]; then
        echo "Error: Please provide a number as an argument." >&2
        return 1
    fi
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: Argument must be a positive integer." >&2
        return 1
    fi

    local number="$1"
    local formatted=""
    local len

    # Process the number from right to left
    while [[ ${#number} -gt 3 ]]; do
        
        len=${#number}
        
        local prefix_len=$(( len - 3 ))
        local part="${number: -3}"

        formatted="$part $formatted"
        number="${number:0:$prefix_len}"
    done
    
    # Prepend the remaining 1, 2, or 3 digits (the start of the number)
    formatted="$number $formatted"
    printf "%s\n" "$formatted"
}

# Source dependancies
source "$HOME/.lsr_core/core/lsr.core.sh"
if [[ -f "$HOME/.env" ]]; then
    source "$HOME/.env"
fi

LSR_COMMAND_SET_HELP "torn.key" "Show information about the current Torn profile"
function torn_key() {
    echo "$TORN_API_KEY";
}

LSR_COMMAND_SET_HELP "torn.profile" "Show information about the current Torn profile"
function torn_profile() {
    local response=$(curl -s "https://api.torn.com/user/$TORN_USER?key=$TORN_API_KEY")
    
    local profile_name="$(echo "$response" | jq -r '.name')"
    local profile_level="$(echo "$response" | jq -r '.level')"
    local profile_age="$(echo "$response" | jq -r '.age')"
    local profile_rank="$(echo "$response" | jq -r '.rank')"
    local profile_partner="$(echo "$response" | jq -r '.married.spouse_name')"
    local profile_marriage_length="$(echo "$response" | jq -r '.married.duration')"

    # echo "$response" | jq '.'

    echo "Hi $profile_name!"
    echo "You are a level $profile_level $profile_rank, and are $profile_age days old."
    echo "You are married to $profile_partner for $profile_marriage_length days."
}

LSR_COMMAND_SET_HELP "torn.stats" "Show information about the current Torn profile"
function torn_stats() {
    local response=$(curl -s "https://api.torn.com/user/$TORN_USER?key=$TORN_API_KEY&selections=bars,battlestats,cooldowns,networth,workstats")
    
    local battle_speed="$(echo "$response" | jq -r '.speed')"
    local battle_dexterity="$(echo "$response" | jq -r '.dexterity')"
    local battle_strength="$(echo "$response" | jq -r '.strength')"
    local battle_defense="$(echo "$response" | jq -r '.defense')"
    local battle_total="$(echo "$response" | jq -r '.total')"

    local work_intelligence="$(echo "$response" | jq -r '.intelligence')"
    local work_endurance="$(echo "$response" | jq -r '.endurance')"
    local work_manual_labor="$(echo "$response" | jq -r '.manual_labor')"

    local networth_cash="$(echo "$response" | jq -r '.networth.wallet')"
    local networth_bank="$(echo "$response" | jq -r '.networth.bank')"
    local networth_items="$(echo "$response" | jq -r '.networth.items')"
    local networth_stock="$(echo "$response" | jq -r '.networth.stockmarket')"
    local networth_total="$(echo "$response" | jq -r '.networth.total')"

    local bars_life="$(echo "$response" | jq -r '.life.current')"
    local bars_life_max="$(echo "$response" | jq -r '.life.maximum')"
    local bars_energy="$(echo "$response" | jq -r '.energy.current')"
    local bars_energy_max="$(echo "$response" | jq -r '.energy.maximum')"
    local bars_nerve="$(echo "$response" | jq -r '.nerve.current')"
    local bars_nerve_max="$(echo "$response" | jq -r '.nerve.maximum')"
    local bars_happyness="$(echo "$response" | jq -r '.happy.current')"
    local bars_happyness_max="$(echo "$response" | jq -r '.happy.maximum')"

    local cooldown_drug="$(echo "$response" | jq -r '.cooldowns.drug')"
    local cooldown_medical="$(echo "$response" | jq -r '.cooldowns.medical')"
    local cooldown_booster="$(echo "$response" | jq -r '.cooldowns.booster')"

    # echo "$response" | jq '.'

    echo "===== BATTLE STATS ====="
    echo "Speed:     $(format_number_with_spaces $battle_speed)"
    echo "Dexterity: $(format_number_with_spaces $battle_dexterity)"
    echo "Strength:  $(format_number_with_spaces $battle_strength)"
    echo "Defense:   $(format_number_with_spaces $battle_defense)"
    echo "Total:     $(format_number_with_spaces $battle_total)"
    echo ""

    echo "===== WORK STATS ====="
    echo "Intelligence: $(format_number_with_spaces $work_intelligence)"
    echo "Endurance:    $(format_number_with_spaces $work_endurance)"
    echo "Manual Labor: $(format_number_with_spaces $work_manual_labor)"
    echo ""

    echo "===== NETWORTH ====="
    echo "Cash:  $(format_number_with_spaces $networth_cash)"
    echo "Bank:  $(format_number_with_spaces $networth_bank)"
    echo "Items: $(format_number_with_spaces $networth_items)"
    echo "Stock: $(format_number_with_spaces $networth_stock)"
    echo "Total: $(format_number_with_spaces $networth_total)"
    echo ""

    echo "===== BARS ====="
    echo "Life:   $bars_life / $bars_life_max"
    echo "Energy: $bars_energy / $bars_energy_max"
    echo "Nerve:  $bars_nerve / $bars_nerve_max"
    echo "Happy:  $bars_happyness / $bars_happyness_max"
    echo ""

    echo "===== COOLDOWNS =====" # Convert to hours
    echo "Drug:    $((cooldown_drug / 3600))h $(((cooldown_drug % 3600) / 60))m $((cooldown_drug % 60))s"
    echo "Medical: $((cooldown_medical / 3600))h $(((cooldown_medical % 3600) / 60))m $((cooldown_medical % 60))s"
    echo "Booster: $((cooldown_booster / 3600))h $(((cooldown_booster % 3600) / 60))m $((cooldown_booster % 60))s"
    echo ""
}

LSR_COMMAND "torn" "$@"