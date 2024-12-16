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

# Vim plugins
mkdir -p "$HOME/.vim/autoload"
echo "source ~/scripts/extra_config_files/plug.vim" > "$HOME/.vim/autoload/plug.vim"

# Create or clear the .vimrc file and write the hardcoded text
echo "source ~/scripts/extra_config_files/LukesVimConfig.vim" > "$HOME/.vimrc"

# Git cli plugins
mkdir -p "$HOME/bin"
cp $HOME/scripts/extra_config_files/git-users.sh $HOME/bin/git-users
chmod +x $HOME/bin/git-users
cp $HOME/scripts/extra_config_files/git-feature.sh $HOME/bin/git-feature
chmod +x $HOME/bin/git-feature

open_db() {
    local IP=$1
    local DB_PW=$2
    local PORT=$3
    local NAME=$4

    # Kill the previous ssh bastion if its still alive
    ssh_pid="$(pgrep -a "ssh" | grep "ssh forge@$IP -N -L $PORT:localhost:3306" | awk '{print $1}')"
    if [[ -n "$ssh_pid" ]]; then
        kill "$ssh_pid"
    fi

    # Open SSH tunnel
    ssh "forge@$IP" -N -L $PORT:localhost:3306 &
}

if [[ -f "$HOME/projects/config.sh" && "$LSR_TYPE" == "LSR-FULL" ]]; then
    source "$HOME/projects/config.sh"
    # open_db $LIVE_IP $LIVE_DB_PW $LIVE_DB_TUNNEL_PORT Live-Server
    # open_db $DEV_IP $DEV_DB_PW $DEV_DB_TUNNEL_PORT Dev-Server
    # open_db $LEGACY_IP $LEGACY_DB_PW $LEGACY_DB_TUNNEL_PORT Legacy-Server
fi

export PATH="$HOME/bin:$PATH"
