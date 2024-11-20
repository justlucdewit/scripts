# Inject the LSR gitconfig in the global gitconfig
CUSTOM_CONFIG="$HOME/scripts/extra_config_files/lsr.gitconfig"
GLOBAL_CONFIG="$HOME/.gitconfig"

if [ ! -f "$GLOBAL_CONFIG" ]; then
    touch "$GLOBAL_CONFIG"
fi

if ! grep -q "$CUSTOM_CONFIG" "$GLOBAL_CONFIG"; then
    echo -e "\n[include]\n\tpath = $CUSTOM_CONFIG" >> "$GLOBAL_CONFIG"
fi

# Inject the LSR global gitignore
GLOBAL_GITIGNORE="$HOME/scripts/extra_config_files/lsr.gitignore"
if ! grep -q "lsr.gitignore" "$GLOBAL_CONFIG"; then
    cat <<EOL >> $GLOBAL_CONFIG
[core]
    excludesfile = $GLOBAL_GITIGNORE
EOL

fi