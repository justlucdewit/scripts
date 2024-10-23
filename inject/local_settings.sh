localsettings_reformat() {
    local yaml_file="$HOME/scripts/local_data/local_settings.yml"
    yq eval --prettyPrint '.' -i "$yaml_file"
}