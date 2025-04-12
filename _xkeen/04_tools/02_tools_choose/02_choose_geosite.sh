# Функция для выбора вариантов GeoSite
choose_geosite() {
    local has_missing_geosite_bases=false
    local has_updatable_geosite_bases=false

    # Проверяем наличие и обновляемость GeoSite баз
    [ "$geo_exists_geosite_v2fly" != "installed" ] && has_missing_geosite_bases=true
    [ "$geo_exists_geosite_antifilter" != "installed" ] && has_missing_geosite_bases=true
    [ "$geo_exists_geosite_antizapret" != "installed" ] && has_missing_geosite_bases=true
	[ "$geo_exists_geosite_zkeen" != "installed" ] && has_missing_geosite_bases=true
    ([ "$geo_exists_geosite_v2fly" = "installed" ] || [ "$geo_exists_geosite_antifilter" = "installed" ] || [ "$geo_exists_geosite_antizapret" = "installed" ] || [ "$geo_exists_geosite_zkeen" = "installed" ]) && has_updatable_geosite_bases=true

    while true; do
        echo 
        echo 
        echo -e "  Выберите номер или номера действий для ${yellow}GeoSite${reset}"
        echo 
        echo "     0. Пропустить"
        [ "$has_missing_geosite_bases" = true ] && echo "     1. Установить отсутствующие GeoSite" || echo -e "     1. ${dark_gray}Все доступные GeoSite установлены${reset}"
        [ "$has_updatable_geosite_bases" = true ] && echo "     2. Обновить установленные GeoSite" || echo -e "     2. ${dark_gray}Нет доступных GeoSite для обновления${reset}"

        [ "$geo_exists_geosite_v2fly" != "installed" ] && v2fly_choice="Установить" || v2fly_choice="Обновить"
        [ "$geo_exists_geosite_antifilter" != "installed" ] && antifilter_choice="Установить" || antifilter_choice="Обновить"
        [ "$geo_exists_geosite_antizapret" != "installed" ] && antizapret_choice="Установить" || antizapret_choice="Обновить"
		[ "$geo_exists_geosite_zkeen" != "installed" ] && zkeen_choice="Установить" || zkeen_choice="Обновить"

        echo "     3. $v2fly_choice v2fly"
        echo "     4. $antifilter_choice AntiFilter"
        echo "     5. $antizapret_choice AntiZapret"
		echo "     6. $zkeen_choice Zkeen"

        [ "$has_updatable_geosite_bases" = true ] && echo "     99. Удалить все GeoSite" || echo -e "     99. ${dark_gray}Нет установленных GeoSite для удаления${reset}"
        echo
        
        local geosite_choices=$(input_digits "Ваш выбор: " "${red}Некорректный номер действия.${reset} Пожалуйста, выберите снова")

        local invalid_choice=false
        for choice in $geosite_choices; do
            if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
                echo -e "  ${red}Некорректный номер действия.${reset} Пожалуйста, выберите снова"
                invalid_choice=true
                break
            fi
        done
        
        for choice in $geosite_choices; do
            if [ "$choice" -eq 0 ]; then
                echo "  Выполнен пропуск установки / обновления GeoSite"
                return
            elif [ "$choice" -eq 1 ]; then
                if [ "$has_missing_geosite_bases" = false ]; then
                    echo -e "  Все GeoSite ${green}уже установлены${reset}"
                    if input_concordance_list "Вы хотите обновить их?"; then
                        update_v2fly_geosite=true
                        update_antifilter_geosite=true
                        update_antizapret_geosite=true
						update_zkeen_geosite=true
                        break
                    else
                        invalid_choice=true
                        break
                    fi
                else
                    if [ "$geo_exists_geosite_v2fly" != "installed" ]; then
                        install_v2fly_geosite=true
                    fi
                    if [ "$geo_exists_geosite_antifilter" != "installed" ]; then
                        install_antifilter_geosite=true
                    fi
                    if [ "$geo_exists_geosite_antizapret" != "installed" ]; then
                        install_antizapret_geosite=true
                    fi
                    if [ "$geo_exists_geosite_zkeen" != "installed" ]; then
                        install_zkeen_geosite=true
                    fi
                fi
            elif [ "$choice" -eq 2 ]; then
                if [ "$has_updatable_geosite_bases" = false ]; then
                    echo -e "  ${red}Нет установленных GeoSite${reset} для обновления"
                    if input_concordance_list "Вы хотите установить их?"; then
                        install_v2fly_geosite=true
                        install_antifilter_geosite=true
                        install_antizapret_geosite=true
						install_zkeen_geosite=true
                        break
                    else
                        invalid_choice=true
                        break
                    fi
                else
                    if [ "$geo_exists_geosite_v2fly" = "installed" ]; then
                        update_v2fly_geosite=true
                    fi
                    if [ "$geo_exists_geosite_antifilter" = "installed" ]; then
                        update_antifilter_geosite=true
                    fi
                    if [ "$geo_exists_geosite_antizapret" = "installed" ]; then
                        update_antizapret_geosite=true
                    fi
                    if [ "$geo_exists_geosite_zkeen" = "installed" ]; then
                        update_zkeen_geosite=true
                    fi
                fi
            elif [ "$choice" -eq 99 ]; then
                if [ "$has_updatable_geosite_bases" = false ]; then
                    echo -e "  ${red}Нет установленных GeoSite для удаления${reset}. Выберите другой пункт"
                    invalid_choice=true
                    break
                else
                    chose_delete_geosite_v2fly_select=true
                    chose_delete_geosite_antifilter_select=true
                    chose_delete_geosite_antizapret_select=true
					chose_delete_geosite_zkeen_select=true
                fi
            elif [ "$choice" -eq 3 ]; then
                [ "$geo_exists_geosite_v2fly" != "installed" ] && install_v2fly_geosite=true || update_v2fly_geosite=true
            elif [ "$choice" -eq 4 ]; then
                [ "$geo_exists_geosite_antifilter" != "installed" ] && install_antifilter_geosite=true || update_antifilter_geosite=true
            elif [ "$choice" -eq 5 ]; then
                [ "$geo_exists_geosite_antizapret" != "installed" ] && install_antizapret_geosite=true || update_antizapret_geosite=true
			elif [ "$choice" -eq 6 ]; then
                [ "$geo_exists_geosite_zkeen" != "installed" ] && install_zkeen_geosite=true || update_zkeen_geosite=true
            fi
        done

        install_list=""
        update_list=""
        delete_list=""

        [ "$install_v2fly_geosite" = true ] && install_list="$install_list ${yellow}v2fly${reset},"
        [ "$install_antifilter_geosite" = true ] && install_list="$install_list ${yellow}AntiFilter${reset},"
        [ "$install_antizapret_geosite" = true ] && install_list="$install_list ${yellow}AntiZapret${reset},"
		[ "$install_zkeen_geosite" = true ] && install_list="$install_list ${yellow}Zkeen${reset},"
        [ "$update_v2fly_geosite" = true ] && update_list="$update_list ${yellow}v2fly${reset},"
        [ "$update_antifilter_geosite" = true ] && update_list="$update_list ${yellow}AntiFilter${reset},"
        [ "$update_antizapret_geosite" = true ] && update_list="$update_list ${yellow}AntiZapret${reset},"
		[ "$update_zkeen_geosite" = true ] && update_list="$update_list ${yellow}Zkeen${reset},"
        [ "$chose_delete_geosite_v2fly_select" = true ] && delete_list="$delete_list ${yellow}v2fly${reset},"
        [ "$chose_delete_geosite_antifilter_select" = true ] && delete_list="$delete_list ${yellow}AntiFilter${reset},"
        [ "$chose_delete_geosite_antizapret_select" = true ] && delete_list="$delete_list ${yellow}AntiZapret${reset},"
		[ "$chose_delete_geosite_zkeen_select" = true ] && delete_list="$delete_list ${yellow}Zkeen${reset},"

        if [ -n "$install_list" ]; then
            echo -e "  Устанавливаются следующие GeoSite: ${install_list%,}"
        fi

        if [ -n "$update_list" ]; then
            echo -e "  Обновляются следующие GeoSite: ${update_list%,}"
        fi

        if [ -n "$delete_list" ]; then
            echo -e "  Удаляются следующие GeoSite: ${delete_list%,}"
        fi
        break
    done
}
