alias goto="goto_main_command"

open_ssh() {
    local IP=$1
    local DIR=$2
    local EXTRA_PROJECTS="tta:/home/forge/timthijssen.x-ingredient.dev"

    scp "$HOME/scripts/versions/dev/build-lite.sh" "forge@$IP:/tmp/temp_carryover_script.sh" >/dev/null
    ssh -t "forge@$IP" "
        echo 'LSR_EXTRA_PROJECTS=\"$EXTRA_PROJECTS\"' >> /tmp/temp_carryover_script.sh
        echo 'rm -f /tmp/temp_carryover_script.sh' >> /tmp/temp_carryover_script.sh
        cd $DIR
        bash --init-file /tmp/temp_carryover_script.sh
    "
}

open_db() {
    local IP=$1
    local PORT=$2
    local NAME=$3

     # Open SSH tunnel if its not still opened
    ssh_pid="$(pgrep -a "ssh" | grep "ssh forge@$IP -N -L $PORT:localhost:3306" | awk '{print $1}')"
    if [[ ! -n "$ssh_pid" ]]; then
        ssh "forge@$IP" -N -L $PORT:localhost:3306 &
        SSH_PID=$!
        echo "Opened SSH tunnel to db $NAME"
    else
        echo "SSH tunnel to db $NAME was already open"
    fi
}

goto_main_command() {
    composite_define_command "goto"
    composite_define_subcommand "repo"
    composite_define_subcommand "docker"

    composite_define_subcommand "server-live"
    composite_define_subcommand "server-dev"
    composite_define_subcommand "server-legacy"
    
    composite_define_subcommand "db-live"
    composite_define_subcommand "db-dev"
    composite_define_subcommand "db-legacy"
    
    composite_define_subcommand "site-live"
    composite_define_subcommand "site-dev"
    composite_define_subcommand "site-legacy"

    composite_define_subcommand "forge-live"
    composite_define_subcommand "forge-dev"
    composite_define_subcommand "forge-legacy"

    composite_handle_subcommand $@
}

goto_repo() {
    source "./_lsr_scripts/_project.sh"
    print_info "opening repo '$REPO_NAME'"
    explorer.exe https://$REPO_URL
}

goto_docker() {
    source "./_lsr_scripts/_project.sh"
    print_info "opening docker shell"
    docker exec -it $CONTAINER_ID /bin/bash
}

goto_server-live() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening SSH to live-server"
    open_ssh $LIVE_IP $LIVE_DIR $LIVE_PROJECTS
}

goto_server-dev() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening SSH to dev-server"
    open_ssh $DEV_IP $DEV_DIR $DEV_PROJECTS
}

goto_server-legacy() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening SSH to legacy-server"
    open_ssh $LEGACY_IP $LEGACY_DIR $LEGACY_PROJECTS
}

goto_db-live() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening live-server db"
    open_db $LIVE_IP $LIVE_DB_TUNNEL_PORT Live-Server
}

goto_db-dev() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening dev-server db"
    open_db $DEV_IP $DEV_DB_TUNNEL_PORT Dev-Server
}

goto_db-legacy() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening legacy-server db"
    open_db $LEGACY_IP $LEGACY_DB_TUNNEL_PORT Legacy-Server
}

goto_site-live() {
    source "./_lsr_scripts/_project.sh"
    print_info "opening live website"
    explorer.exe https://$LIVE_URL
}

goto_site-dev() {
    source "./_lsr_scripts/_project.sh"
    print_info "opening dev website"
    explorer.exe http://$DEV_URL
}

goto_site-legacy() {
    source "./_lsr_scripts/_project.sh"
    print_info "opening legacy website"
    explorer.exe http://$LEGACY_URL
}

goto_forge-live() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening forge-live Application"
    explorer.exe https://forge.laravel.com/servers/$LIVE_ID/sites/$LIVE_SITE_ID/application
}

goto_forge-dev() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening forge-live Application"
    explorer.exe https://forge.laravel.com/servers/$DEV_ID/sites/$DEV_SITE_ID/application
}

goto_forge-legacy() {
    source "./_lsr_scripts/_project.sh"
    source "$HOME/projects/config.sh"
    print_info "opening forge-live Application"
    explorer.exe https://forge.laravel.com/servers/$LEGACY_ID/sites/$LEGACY_SITE_ID/application
}
