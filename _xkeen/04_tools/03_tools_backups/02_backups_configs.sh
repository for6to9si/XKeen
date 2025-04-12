# Работа с резервными копиями конфигураций

backup_configs() {
    local backup_filename="${current_datetime}_configs"
    local backup_configs_dir="$backups_dir/$backup_filename"

    if [ -n "$(ls -A "$install_conf_dir")" ]; then
        mkdir -p "$backup_configs_dir"

        cp -r "$install_conf_dir"/* "$backup_configs_dir/"

        if [ $? -eq 0 ]; then
            echo -e "  Резервная копия конфигураций Xray создана: ${yellow}$backup_filename${reset}"
        else
            echo -e "  ${red}Ошибка при создании резервной копии конфигураций Xray${reset}"
        fi
    else
        echo -e "  ${yellow}Нет файлов для создания резервной копии конфигураций Xray${reset}"
    fi
}

restore_backup_configs() {
    local latest_backup=$(ls -t "$backups_dir" | grep "configs" | head -n 1)

    if [ -n "$latest_backup" ]; then
        backup_path="$backups_dir/$latest_backup"

        if [ ! -d "$install_conf_dir" ]; then
            mkdir -p "$install_conf_dir"
        else
            rm -f "$install_conf_dir"/*
        fi

        cp -r "$backup_path"/* "$install_conf_dir/"

		echo -e "  Работа с конфигурациями ${green}успешно завершена${reset}."
	fi
}
