alias ls="overwrite_ls"

overwrite_ls() {
    local dirs_list_txt=""
    local symlink_list_txt=""
    local files_list_txt=""
    local executable_list_txt=""

    # Run `ls -l` and process output line by line
    while read -r line; do
        # Split the line into components
        permissions=$(echo "$line" | awk '{print $1}')
        links=$(echo "$line" | awk '{print $2}')
        owner=$(echo "$line" | awk '{print $3}')
        group=$(echo "$line" | awk '{print $4}')
        size=$(echo "$line" | awk '{print $5}')
        date=$(echo "$line" | awk '{print $6, $7, $8}')
        name=$(echo "$line" | awk '{for (i=9; i<=NF; i++) printf $i " "; print ""}' | sed 's/ *$//')
        
        # Determine the type based on the first character of the permissions
        case "$permissions" in
            d*) type="dir" ;;
            l*) type="symlink" ;;
            -*)
                if [[ -x "$name" ]]; then
                    type="executable"
                else
                    type="file"
                fi
                ;;
            *) type="unknown" ;;
        esac

        # Check if the file/folder is hidden (starts with a dot)
        if [[ "$name" == .* ]]; then
            hidden="true"
        else
            hidden="false"
        fi

        # Check if the file/folder is accessible
        if [[ -r "$name" && -x "$name" ]]; then
            accessible="true"
        else
            accessible="false"
        fi

        # Output the parsed information
        # echo "Entry: $name"
        # echo "  Type: $type"
        # echo "  Hidden: $hidden"
        # echo "  Accessible: $accessible"
        # echo "  Permissions: $permissions"
        # echo "  Links: $links"
        # echo "  Owner: $owner"
        # echo "  Group: $group"
        # echo "  Size: $size"
        # echo "  Date: $date"
        # echo

        if [[ "$type" == "dir" && "$name" != "." && "$name" != ".." ]]; then
            if [[ -n "$dirs_list_txt$symlink_list_txt$files_list_txt$executable_list_txt" ]]; then
                dirs_list_txt+=$'\n'
            fi
            
            dirs_list_txt+=" 🗂️ $name"
        fi

        if [[ "$type" == "symlink" ]]; then
            if [[ -n "$dirs_list_txt$symlink_list_txt$files_list_txt$executable_list_txt" ]]; then
                symlink_list_txt+=$'\n'
            fi

            symlink_list_txt+=" 🔗 $name"
        fi

        if [[ "$type" == "file" ]]; then
            if [[ -n "$dirs_list_txt$symlink_list_txt$files_list_txt$executable_list_txt" ]]; then
                files_list_txt+=$'\n'
            fi

            files_list_txt+=" 📄 $name"
        fi

        if [[ "$type" == "executable" ]]; then
            if [[ -n "$dirs_list_txt$symlink_list_txt$files_list_txt$executable_list_txt" ]]; then
                executable_list_txt+=$'\n'
            fi

            executable_list_txt+=" ⚙️ $name"
        fi
    done < <($LSR_ORIGINAL_LS -l "$1" | tail -n +2)

    echo -n "$dirs_list_txt"
    echo -n "$symlink_list_txt"
    echo -n "$files_list_txt"
    echo -n "$executable_list_txt"
    echo
    echo
}