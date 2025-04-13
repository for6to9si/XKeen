data_is_updated_exclude() {
    local file="$1"
    local new_delay="$2"
    local current_delay=$(
        awk -F= '/start_delay/{print $2; exit}' "$file" \
        | tr -d '"'
    )
    if [ "$current_delay" = "$new_delay" ]; then
        return 0
    else
        return 1
    fi
}

update_start_delay() {
    local new_delay="$1"

    # Проверка, что new_delay не пусто
    if [ -z "$new_delay" ]; then
        echo -e "  ${red}Ошибка${reset}"
		echo "  Новая задержка не может быть пустой"
        return 1
    fi

    # Проверка, что new_delay - это число
    if ! [ "$new_delay" -eq "$new_delay" ] 2>/dev/null; then
        echo -e "  ${red}Ошибка${reset}"
		echo "  Новая задержка должна быть числом"
        return 1
    fi

    local current_delay=$(
        awk -F= '/start_delay/{print $2; exit}' "$initd_dir/S24xray" \
        | tr -d '[:space:]'
    )
    current_delay=${current_delay:-""}

    local tmpfile=$(mktemp)
    awk -v new_delay="start_delay=$new_delay" 'BEGIN{replaced=0} /start_delay/ && !replaced {sub(/start_delay=[^ ]*/, new_delay); replaced=1} {print}' "$initd_dir/S24xray" > "$tmpfile" && mv "$tmpfile" "$initd_dir/S24xray"

    while true; do
        if data_is_updated_exclude "$initd_dir/S24xray" "$new_delay"; then
            break
        fi
        sleep 1
    done

    echo -e "  ${green}Успех${reset}"
	echo -e "  Стартовая задержка запуска обновлена до ${new_delay} секунд(ы)"
}
