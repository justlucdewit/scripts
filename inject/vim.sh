# Function to setup vim-plug for Vim
setup_vim_plug() {
    # Define the directory and file
    local vim_autoload_dir="$HOME/.vim/autoload"
    local plug_file="$vim_autoload_dir/plug.vim"

    # Create the autoload directory if it doesn't exist
    if [ ! -d "$vim_autoload_dir" ]; then
        mkdir -p "$vim_autoload_dir"
        print_info "Created directory: $vim_autoload_dir"
    fi

    # Download plug.vim if it doesn't exist
    if [ ! -f "$plug_file" ]; then
        curl -fLo "$plug_file" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        print_info "Downloaded vim-plug to $plug_file"
    fi
}


# Setting settings of vim
write_to_vimrc() {
    local vimrc_file="$HOME/.vimrc"

    setup_vim_plug

    # Hardcoded Vim configuration
    local vimrc_text="
source ~/scripts/extra_config_files/LukesVimConfig.vim
"

    # Create or clear the .vimrc file and write the hardcoded text
    echo "$vimrc_text" > "$vimrc_file"
}

write_to_vimrc