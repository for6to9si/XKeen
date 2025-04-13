# Функция для удаления cron задач
delete_cron_task() {
    if [ "$chose_cancel_cron_select" != true ]; then
        if [ -f "$cron_dir/$cron_file" ]; then
            tmp_file="$cron_dir/${cron_file}.tmp"
            
            cp "$cron_dir/$cron_file" "$tmp_file"
            
            if [ "$chose_all_cron_select" = true ] || [ "$chose_delete_all_cron_select" = true ]; then
                grep -v "ug" "$tmp_file" | grep -v "uk" | grep -v "ux" | sed '/^\s*$/d' > "$cron_dir/$cron_file"
            else
                if [ "$chose_geofile_cron_select" = true ]; then
                    delete_cron_geofile
                fi

                if [ "$chose_xkeen_cron_select" = true ]; then
                    delete_cron_xkeen
                fi
                
                if [ "$chose_xray_cron_select" = true ]; then
                    delete_cron_xray
                fi
            fi
        fi
    fi
}

# Функция для удаления cron задач для GeoFile
delete_cron_geofile() {
    if [ -f "$cron_dir/$cron_file" ]; then
        tmp_file="$cron_dir/${cron_file}.tmp"
        
        cp "$cron_dir/$cron_file" "$tmp_file"
        
        grep -v "ug" "$tmp_file" | sed '/^\s*$/d' > "$cron_dir/$cron_file"
    fi
}

# Функция для удаления cron задач для XKeen
delete_cron_xkeen() {
    if [ -f "$cron_dir/$cron_file" ]; then
        tmp_file="$cron_dir/${cron_file}.tmp"
        
        cp "$cron_dir/$cron_file" "$tmp_file"
        
        grep -v "uk" "$tmp_file" | sed '/^\s*$/d' > "$cron_dir/$cron_file"
    fi
}

# Функция для удаления cron задач для Xray
delete_cron_xray() {
    if [ -f "$cron_dir/$cron_file" ]; then
        tmp_file="$cron_dir/${cron_file}.tmp"
        
        cp "$cron_dir/$cron_file" "$tmp_file"
        
        grep -v "ux" "$tmp_file" | sed '/^\s*$/d' > "$cron_dir/$cron_file"
    fi
}
