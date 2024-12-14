
# Inject the LSR gitconfig in the global gitconfig
if [[ "$LSR_TYPE" != "LSR-LITE" ]]; then
    CUSTOM_CONFIG="$HOME/scripts/extra_config_files/lsr.gitconfig"
    GLOBAL_CONFIG="$HOME/.gitconfig"

    if [ ! -f "$GLOBAL_CONFIG" ]; then
        touch "$GLOBAL_CONFIG"
    fi

    if ! grep -q "$CUSTOM_CONFIG" "$GLOBAL_CONFIG"; then
        echo -e "\n[include]\n\tpath = $CUSTOM_CONFIG" >> "$GLOBAL_CONFIG"
    fi
fi

# Inject the LSR global gitignore
if [[ "$LSR_TYPE" != "LSR-LITE" ]]; then
    GLOBAL_GITIGNORE="$HOME/scripts/extra_config_files/lsr.gitignore"
    if ! grep -q "lsr.gitignore" "$GLOBAL_CONFIG"; then
        cat <<EOL >> $GLOBAL_CONFIG
[core]
    excludesfile = $GLOBAL_GITIGNORE
EOL

    fi
fi

# Vim plugins
if [[ "$LSR_TYPE" != "LSR-LITE" ]]; then
    mkdir -p "$HOME/.vim/autoload"
    echo "source ~/scripts/extra_config_files/plug.vim" > "$HOME/.vim/autoload/plug.vim"

    # Create or clear the .vimrc file and write the hardcoded text
    echo "source ~/scripts/extra_config_files/LukesVimConfig.vim" > "$HOME/.vimrc"
fi

# Hide tmux bar
if [[ "$LSR_TYPE" != "LSR-LITE" ]]; then
    tmux set -g status off
fi