# Определение статуса для задач cron

choose_update_cron() {
    local has_updatable_cron_tasks=false
    [ "$info_update_geofile_cron" = "installed" ] && has_updatable_cron_tasks=true

    echo
    echo

    echo -e "  ${yellow}Выберите номер действия${reset} для автообновления GeoFile"
    echo
    echo "     0. Пропустить"

    [ "$info_update_geofile_cron" != "installed" ] && geofile_choice="Включить" || geofile_choice="Обновить"

    echo "     1. $geofile_choice задачу"

    if [ "$has_updatable_cron_tasks" = true ]; then
        echo "     99. Выключить автообновление"
    fi

    echo

    local update_choices=$(input_digits "Ваш выбор: " "${red}Некорректный номер действия. ${reset}Пожалуйста, выберите снова")

    local invalid_choice=false
    for choice in $update_choices; do
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo -e "  ${red}Некорректный номер действия.${reset} Пожалуйста, выберите снова"
            invalid_choice=true
            break
        fi
    done

    for choice in $update_choices; do
        case "$choice" in
            0)
                chose_canel_cron_select=true
                ;;
            1)
                if [ "$info_update_geofile_cron" = "installed" ]; then
                    chose_geofile_cron_select=true
                    echo -e "  ${yellow}Будет выполнено${reset} обновление задачи GeoFile"
                else
                    chose_geofile_cron_select=true
                    echo -e "  ${yellow}Будет выполнено${reset} включение задачи GeoFile"
                fi
                ;;

            99)
                if [ "$has_updatable_cron_tasks" = true ]; then
                    chose_delete_all_cron_select=true
                    echo "  Будет выключено автообновление GeoFile"
                else
                    echo -e "  Автообновление GeoFile ${yellow}не включено${reset}"
                fi
                ;;
            *)
                echo -e "  ${red}Некорректный номер действия.${reset} Пожалуйста, выберите снова"
                ;;
        esac
    done
}
