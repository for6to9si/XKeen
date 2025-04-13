# Функция для установки Xray
install_xray() {
    # Определение переменных
    local xray_archive="${tmp_dir}/xray.zip"
    local info_content=""
    local error_content=""

    # Проверка наличия архива xray
    if [ -f "${xray_archive}" ]; then
        info_content="[info] Архив xray найден\n"

        # Проверка наличия файла xray и создание резервной копии при необходимости
        [ -f "$install_dir/xray" ] && backup_xray

        # Распаковка архива xray
        if unzip -q "${xray_archive}" -d "${tmp_dir}/xray"; then
            info_content="${info_content}[info] Распаковка архива xray выполнена\n"
            
            # Перемещение файла xray
            if mv "${tmp_dir}/xray/xray" $install_dir/; then
                info_content="${info_content}[info] Xray успешно установлен в $install_dir/\n"
                
                # Установка исполняемых прав для Xray
                if chmod +x $install_dir/xray; then
                    info_content="${info_content}[info] Установлены исполняемые права для Xray\n"
                else
                    error_content="${error_content}[error] Ошибка при установке исполняемых прав для Xray\n"
                fi
            else
                error_content="${error_content}[error] Ошибка при перемещении Xray\n"
            fi
        else
            error_content="${error_content}[error] Ошибка при распаковке архива xray\n"
        fi

        # Удаление архива xray
        if rm "${xray_archive}"; then
            info_content="${info_content}[info] Архив xray удален\n"
        else
            error_content="${error_content}[error] Ошибка при удалении архива xray\n"
        fi

        # Удаление временных файлов
        if rm -rf "${tmp_dir}/xray"; then
            info_content="${info_content}[info] Временные файлы удалены\n"
        else
            error_content="${error_content}[error] Ошибка при удалении временных файлов\n"
        fi

    else
        error_content="[error] Архив xray не найден\n"
    fi

    # Запись информации и ошибок в соответствующие логи
    [ -n "${info_content}" ] && echo -e "${info_content}" >> "${xkeen_info_log}"
    [ -n "${error_content}" ] && echo -e "${error_content}" >> "${xkeen_error_log}"
}