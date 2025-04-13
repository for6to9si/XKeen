# Функция для установки и обновления GeoSite
install_geosite() {
    mkdir -p "$geo_dir" || { echo "Ошибка: Не удалось создать директорию $geo_dir"; exit 1; }

    if [ -f "$geo_dir/geosite_antifilter.dat" ]; then
        update_antifilter_geosite_msg=true
    fi
    if [ -f "$geo_dir/geosite_v2fly.dat" ]; then
        update_v2fly_geosite_msg=true
    fi
    if [ -f "$geo_dir/geosite_zkeen.dat" ]; then
        update_zkeen_geosite_msg=true
    fi

    # Установка GeoSite AntiFilter
    if [ "$install_antifilter_geosite" = true ]; then
        curl -L -o "$geo_dir/geosite_antifilter.dat" "https://github.com/Skrill0/AntiFilter-Domains/releases/latest/download/geosite.dat" > /dev/null 2>&1
        if [ $? -eq 0 ] && [ -s "$geo_dir/geosite_antifilter.dat" ]; then
            if [ "$update_antifilter_geosite_msg" = true ]; then
                echo -e "  GeoSite AntiFilter ${green}успешно обновлен${reset}"
            else
                echo -e "  GeoSite AntiFilter ${green}успешно установлен${reset}"
            fi
        else
            echo -e "  ${red}Неизвестная ошибка${reset} при установке GeoSite AntiFilter"
        fi
    fi

    # Установка GeoSite V2Fly
    if [ "$install_v2fly_geosite" = true ]; then
        curl -L -o "$geo_dir/geosite_v2fly.dat" "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" > /dev/null 2>&1
        if [ $? -eq 0 ] && [ -s "$geo_dir/geosite_v2fly.dat" ]; then
            if [ "$update_v2fly_geosite_msg" = true ]; then
                echo -e "  GeoSite V2fly ${green}успешно обновлен${reset}"
            else
                echo -e "  GeoSite V2Fly ${green}успешно установлен${reset}"
            fi
        else
            echo -e "  ${red}Неизвестная ошибка${reset} при установке GeoSite V2Fly"
        fi
    fi
	
    # Установка GeoSite by Zkeen
    if [ "$install_zkeen_geosite" = true ]; then
        # Очистка перед установкой если ранее были созданы симлинки
            rm -f "$geo_dir/zkeen.dat" "$geo_dir/geosite_zkeen.dat"
	    sleep 2
        curl -L -o "$geo_dir/geosite_zkeen.dat" "https://github.com/jameszeroX/zkeen-domains/releases/latest/download/zkeen.dat" > /dev/null 2>&1
        ln -s "$geo_dir/geosite_zkeen.dat" "$geo_dir/zkeen.dat"
        if [ $? -eq 0 ] && [ -s "$geo_dir/geosite_zkeen.dat" ]; then
            if [ "$update_zkeen_geosite_msg" = true ]; then
                echo -e "  GeoSite Zkeen ${green}успешно обновлен${reset}"
            else
                echo -e "  GeoSite Zkeen ${green}успешно установлен${reset}"
            fi
        else
            echo -e "  ${red}Неизвестная ошибка${reset} при установке GeoSite Zkeen"
        fi
    fi

    # Обновление GeoSite AntiFilter, если установлены и требуется обновление
    if [ "$update_antifilter_geosite" = true ] && [ -f "$geo_dir/geosite_antifilter.dat" ]; then
        curl -L -o "$geo_dir/geosite_antifilter.dat" "https://github.com/Skrill0/AntiFilter-Domains/releases/latest/download/geosite.dat" > /dev/null 2>&1	
        if [ $? -eq 0 ] && [ -s "$geo_dir/geosite_antifilter.dat" ]; then
            echo -e "  GeoSite AntiFilter ${green}успешно обновлен${reset}"
        else
            echo -e "  ${red}Неизвестная ошибка${reset} при обновлении GeoSite AntiFilter"
        fi
    fi

    # Обновление GeoSite V2Fly, если установлены и требуется обновление
    if [ "$update_v2fly_geosite" = true ] && [ -f "$geo_dir/geosite_v2fly.dat" ]; then
        curl -L -o "$geo_dir/geosite_v2fly.dat" "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" > /dev/null 2>&1
        if [ $? -eq 0 ] && [ -s "$geo_dir/geosite_v2fly.dat" ]; then
            echo -e "  GeoSite V2Fly ${green}успешно обновлен${reset}"
        else
            echo -e "  ${red}Неизвестная ошибка${reset} при обновлении GeoSite V2Fly"
        fi
    fi

	# Обновление GeoSite Zkeen, если установлены и требуется обновление
    if [ "$update_zkeen_geosite" = true ] && [ -f "$geo_dir/geosite_zkeen.dat" ]; then
        # Очистка перед обновлением если ранее были созданы симлинки
            rm -f "$geo_dir/zkeen.dat" "$geo_dir/geosite_zkeen.dat"
	    sleep 2
        curl -L -o "$geo_dir/geosite_zkeen.dat" "https://github.com/jameszeroX/zkeen-domains/releases/latest/download/zkeen.dat" > /dev/null 2>&1
        ln -s "$geo_dir/geosite_zkeen.dat" "$geo_dir/zkeen.dat"
        if [ $? -eq 0 ] && [ -s "$geo_dir/geosite_zkeen.dat" ]; then
            echo -e "  GeoSite Zkeen ${green}успешно обновлен${reset}"
        else
            echo -e "  ${red}Неизвестная ошибка${reset} при обновлении GeoSite Zkeen"
        fi
    fi

}
