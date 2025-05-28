# Загрузка Xray

download_xray() {
    printf "${yellow}Запрос информации${reset} о ${green}финальных${reset} релизах Xray\n"
    RELEASE_TAGS=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases?per_page=20 | jq -r '.[] | select(.prerelease == false) | .tag_name' | head -n 9)

    if [ -z "$RELEASE_TAGS" ]; then
        printf "${red}Не удалось${reset} получить список релизов. Проверьте соединение с интернетом.\n"
        exit 1
    fi

    printf "\nСписок релизов:\n"
    echo "$RELEASE_TAGS" | awk '{printf "%2d) %s\n", NR, $0}'

    printf "\nВведите порядковый номер релиза Xray: "
    read choice

        if ! echo "$choice" | grep -Eq '^[0-9]+$'; then
            printf "${red}Некорректный${reset} ввод.\n"
            exit 1
        fi
        if echo "$choice" | grep "0"; then
            bypass_xray="true"
        fi

    if [ -z $bypass_xray ]; then
        version_selected=$(echo "$RELEASE_TAGS" | sed -n "${choice}p")
        if [ -z "$version_selected" ]; then
            printf "Выбранный номер ${red}вне диапазона.${reset}\n"
            exit 1
        fi
        VERSION_ARG="$version_selected"
    
        URL_BASE="https://github.com/XTLS/Xray-core/releases/download/$VERSION_ARG"
    
        case $architecture in
            "arm64-v8a")
                download_url="$URL_BASE/Xray-linux-arm64-v8a.zip"
                ;;
            "mips32le")
                download_url="$URL_BASE/Xray-linux-mips32le.zip"
                ;;
            "mips")
                download_url="$URL_BASE/Xray-linux-mips32.zip"
                ;;
            "mips64")
                download_url="$URL_BASE/Xray-linux-mips64.zip"
                ;;
            "mips64le")
                download_url="$URL_BASE/Xray-linux-mips64le.zip"
                ;;
            "arm32-v5")
                download_url="$URL_BASE/Xray-linux-arm32-v5.zip"
                ;;
        esac
    
        # Если URL для загрузки доступен
        if [ -n "$download_url" ]; then
            filename=$(basename "$download_url")
            extension="${filename##*.}"
            
            # Создание временной директории для загрузки файла
            mkdir -p "$xtmp_dir"
            
            echo -e "  ${yellow}Выполняется загрузка${reset} выбранной версии Xray"
    
            # Загрузка файла с использованием c URL и сохранение его во временной директории
            curl -L -o "$xtmp_dir/$filename" "$download_url" &> /dev/null
    
            # Если файл был успешно загружен
            if [ -e "$xtmp_dir/$filename" ]; then
                mv "$xtmp_dir/$filename" "$xtmp_dir/xray.$extension"
                echo -e "  Xray ${green}успешно загружен${reset}"
            else
                echo -e "  ${red}Ошибка${reset} при загрузке файла"
            fi
        else
            echo -e "  ${red}Ошибка${reset}: Не удалось получить URL для загрузки Xray"
        fi
    fi
}
