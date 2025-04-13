# Регистрация xray

register_xray_control() {

    # Создание файла xray.control
    cat << EOF > "$register_dir/xray_s.control"
Package: xray_s
Version: $xray_current_version
Depends: libc, libssp, librt, libpthread, ca-bundle
Source: XTLS Team
SourceName: xray_s
Section: net
SourceDateEpoch: $source_date_epoch
Maintainer: Skrill
Architecture: $status_architecture
Installed-Size: $installed_size
Description: A unified platform for anti-censorship.
EOF
}

register_xray_list() {
    cd "$register_dir/" || exit
    touch xray_s.list

# Генерация списка файлов
    find /opt/etc/xray/dat -type f | while read file; do
        echo "$file" >> xray_s.list
    done

    find /opt/etc/xray/configs -type f | while read file; do
        echo "$file" >> xray_s.list
    done

    find /opt/var/log/xray -type f | while read file; do
        echo "$file" >> xray_s.list
    done

    # Добавление дополнительных путей
    echo "/opt/var/log/xray" >> xray_s.list
    echo "/opt/etc/xray/configs" >> xray_s.list
	echo "/opt/etc/xray/dat" >> xray_s.list
	echo "/opt/etc/xray" >> xray_s.list
	echo "/opt/sbin/xray" >> xray_s.list
	echo "/opt/etc/init.d/S24xray" >> xray_s.list
}

register_xray_status() {
    # Генерация хэш-сумм для .json файлов
    temp_file=$(mktemp)
    for file in "$install_conf_dir"/*.json; do
        filename=$(basename "$file")
        hash_value=$(sha256sum "$file" | awk '{print $1}')
        echo "$filename $hash_value" >> $temp_file
    done

    # Генерация новой записи
    echo "Package: xray_s" > new_entry.txt
    echo "Version: $xray_current_version" >> new_entry.txt
    echo "Depends: libc, libssp, librt, libpthread, ca-bundle" >> new_entry.txt
    echo "Status: install user installed" >> new_entry.txt
    echo "Architecture: $status_architecture" >> new_entry.txt
    echo "Conffiles:" >> new_entry.txt

    while read line; do
        filename=$(echo $line | cut -d' ' -f1)
        hash=$(echo $line | cut -d' ' -f2)
        echo "/opt/etc/xray/configs/$filename $hash" >> new_entry.txt
    done < $temp_file

    echo "Installed-Time: $(date +%s)" >> new_entry.txt

    # Удаление временного файла
    rm $temp_file

    # Чтение существующего содержимого файла "status"
    existing_content=$(cat "$status_file")

    # Объединение существующего содержимого и новой записи
    echo -e "\n$(cat new_entry.txt)" >> "$status_file"
}

register_xray_initd() {
	local initd_file="${initd_dir}/S24xray"
    local s24xray_filename="${current_datetime}_S24xray"
    local backup_path="${backups_dir}/${s24xray_filename}"
    local script_file="${xinstall_dir}/07_install_register/04_register_init.sh"
    local variables_to_extract="name_client name_policy table_id table_mark port_dns ipv4_proxy ipv4_exclude ipv6_proxy ipv6_exclude port_donor port_exclude start_attempts start_delay start_auto"
    local temp_file=$(mktemp)

    if [ ! -e "${initd_file}" ]; then
        cp "${script_file}" "${initd_file}"
        chmod +x "${initd_file}"
        chmod 755 "${initd_file}"
        echo "  Файл автозапуска создан и обновлен"
        return
    fi

    local script_version=$(grep -m 1 -E 'Версия:|Version:' "${initd_file}" | grep -o '[0-9.]\+')
    local new_script_version=$(grep -m 1 -E 'Версия:|Version:' "${script_file}" | grep -o '[0-9.]\+')

    if [ "${script_version}" = "${new_script_version}" ]; then
        echo "  Обновление файла автозапуска не требуется"
        return
    fi

    if [ "${script_version}" = "x.x" ]; then
        echo "  Файл автозапуска не будет обновлен, так как установлен запрет пользователем с помощью «x.x»"
        return
    fi


    if [ "${new_script_version}" != "${script_version}" ]; then
		mv "${initd_file}" "${backup_path}"
		echo -e "  Ваш файл «${green}S24xray${reset}» перемещен в каталог резервных копий «${yellow}${backup_path}${reset}»"

		cat "${script_file}" > "${initd_file}"

		for var in $variables_to_extract; do
			value=$(grep "^${var}=" "${backup_path}" | head -n 1)
			position=$(grep -n "^${var}=" "${initd_file}" | head -n 1 | cut -d: -f1)

			if [ -n "$position" ]; then
				sed -i "${position}s#.*#${value}#" "${initd_file}"
			fi
		done
    fi

    chmod +x "${initd_file}"
    chmod 755 "${initd_file}"
}
