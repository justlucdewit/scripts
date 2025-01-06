alias true=0
alias false=1

print_warn() {
    echo -e "\e[33m[warn] $1\e[0m"  # \e[34m is the color code for blue
}

print_info() {
    echo -e "\e[34m[info] $1\e[0m"  # \e[34m is the color code for blue
}

print_error() {
    echo -e "\e[31m[error] $1\e[0m"  # \e[31m is the color code for red
}

print_success() {
    echo -e "\e[32m[success] $1\e[0m"  # \e[32m is the color code for green
}

type="$1"
version="$2"

if [[ -z $type || -z $version ]]; then
	print_error "Wrong usage of install command. make sure you properly passed the LSR type and version"
	exit
fi

if [[ $type != "full" && $type != "lite" ]]; then
	print_error "Type must be either full or lite, not '$type'"
	exit
fi

packages_all_installed=true
requires_package() {
    local packageName=$1
    local installation_command=$2

    local output=$(command -v "$1")

    if [[ "$output" == "" ]]; then
    	packages_all_installed=false
        print_warn "Package '$packageName' is required to install LSR"

        if [[ -n "$installation_command" ]]; then
        	print_warn "To install, run '$installation_command'"
        fi

        echo
        return 1
    fi

    return 0
}

setup_local_settings() {
	if [[ ! -f "$HOME/scripts/_settings.yml" ]]; then
		{
			echo -e "name: Lukes Script Repository"
			echo -e "version:"
			echo -e "  major: 1"
			echo -e "  minor: 3"
			echo -e "debug: false"
			echo -e "silent: false"
			echo -e "dev: true"
			echo -e "lite: false"
		} > "$HOME/scripts/_settings.yml"
	fi
}

install_lsr() {
	# Define needed variables
	BASHRC_IDENTIFIER="# Luke's Script Repository Loader"
	BASHRC_PATH="$HOME/.bashrc"
	LOCAL_DATA_DIR="$HOME/scripts/local_data"
	INJECTION_CODE=""
	BASHRC_STARTER="# !! LSR LOADER START !!"
    BASHRC_ENDERER="# !! LSR LOADER END !!"
	BUILD_FILE_PATH="$HOME/scripts/versions/$version/build-lite.sh"
    if [[ $type == "full" ]]; then
    	BUILD_FILE_PATH="$HOME/scripts/versions/$version/build.sh"
	fi

	mkdir -p "$LOCAL_DATA_DIR"

	# Check if there is already an injection in bashrc
    if grep -q "$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
    	print_info "Uninstalling current LSR version..."
        
    	# Check if the LSR loader section exists before attempting to remove it
	    if grep -q "^$BASHRC_IDENTIFIER" "$BASHRC_PATH"; then
	        # Remove the LSR loader section from .bashrc
	        sed -i "/^$BASHRC_STARTER/,/^$BASHRC_ENDERER/d" "$BASHRC_PATH"
	        print_info "Removed LSR loader from $BASHRC_PATH"
	    fi
    fi

    # Install LSR into the bashrc
    print_info "Installing LSR $version..."

    {
	    echo -e "\n\n$BASHRC_STARTER\n$BASHRC_IDENTIFIER\n"
	    echo -e "source \"$BUILD_FILE_PATH\" # Load LSR in current session\n" # Source the script
	    echo -e "print_info \"LSR $version $type Has been loaded in current session\"\n" # Source the script
	    echo -e "$BASHRC_ENDERER"
	} >> "$BASHRC_PATH"

	print_info "Injected script sourcing block into $BASHRC_PATH"
    print_success "Installation of $version $type was succefull\n"
	exec "$(which bash)" --login
}

# See if the required packages for yq are available
clear
print_info "Checking requirements..."
requires_package "yq" "apt-get install yq"
requires_package "jq" "apt-get install jq"
requires_package "curl"
requires_package "bash"
requires_package "node" "apt-get install nodejs"
requires_package "npm"
requires_package "git"

if [[ $packages_all_installed == true ]]; then
	setup_local_settings
	install_lsr
fi