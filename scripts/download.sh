# Stand-alone script to download versions of LSR locally
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

version="$1"

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

download_version() {
	# Find latest version
	if [[ -z "$version" ]]; then
		print_info "Attempting to find latest LSR version..."
		version="$(curl -s https://api.github.com/repos/justlucdewit/scripts/releases | jq -r ".[0].name")"
	fi

	if [[ -f "$HOME/scripts/versions/$version/build-full.sh" ]]; then
		print_warn "LSR $version is already downloaded"
		exit
	fi

	# Create the version folder
	print_info "Downloading LSR $version..."
	local version_dir="$HOME/scripts/versions/$version"
	mkdir -p "$version_dir"

	# Download the latest version to the version folder
	wget "https://github.com/justlucdewit/scripts/releases/download/$version/build.sh" -qO "$HOME/scripts/versions/$version/build-lite.sh" >/dev/null

	if [[ $? != 0 ]]; then
		print_error "Could not download LSR FULL $version, check if version exists"
		exit
	fi

	wget "https://github.com/justlucdewit/scripts/releases/download/$version/build-lite.sh" -qO "$HOME/scripts/versions/$version/build-full.sh" >/dev/null

	if [[ $? != 0 ]]; then
		print_error "Could not download LSR LITE $version, check if version exists"
		exit
	fi
}

clear
print_info "Checking requirements..."
requires_package "yq" "apt-get install yq"
requires_package "jq" "apt-get install jq"
requires_package "curl"
requires_package "bash"
requires_package "node" "apt-get install nodejs"
requires_package "npm"
requires_package "git"
requires_package "wget"
requires_package "curl"

if [[ $packages_all_installed == true ]]; then
	download_version
fi

