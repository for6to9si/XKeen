# Удаление временных файлов и директорий
delete_tmp() {
    if [ -d "$tmp_dir_global/xkeen" ]; then
        rm -r "$tmp_dir_global/xkeen"
    fi

    if [ -f "$cron_dir/root.tmp" ]; then
        rm "$cron_dir/root.tmp"
    fi
	
    if [ -f "/opt/etc/ndm/netfilter.d/xray.sh" ]; then
        rm "/opt/etc/ndm/netfilter.d/xray.sh"
    fi
	
	echo -e "  Выполняется ${yellow}очистка временных файлов${reset} после работы Xkeen"
	sleep 1
	echo -e "  Очистка временных файлов ${green}успешно выполнена${reset}"
}
