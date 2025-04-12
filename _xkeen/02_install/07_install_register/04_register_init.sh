#!/bin/sh

# Информация о службе
# Краткое описание: Запуск / Остановка Xray
# Версия: 2.20
# Если указать в версии «x.x» без кавычек — файл не будет обновляться

# Окружение
path="/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin"

# Цвета
color_green="\033[32m"
color_red="\033[31m"
color_yellow="\033[33m"
color_reset="\033[0m"

# Имена
name_client="xray"
name_app="XKeen"
name_policy="xkeen"
name_profile="xkeen"
name_chain="xkeen"
name_prerouting_chain="${name_chain}"
name_output_chain="${name_chain}_mask"

# Директории
directory_entware="/opt"
directory_os_lib="/lib"
directory_os_modules="${directory_os_lib}/modules/$(uname -r)"
directory_user_lib="${directory_entware}/lib"
directory_user_modules="${directory_user_lib}/modules"
directory_binaries="${directory_entware}/sbin"
directory_temporary="${directory_entware}/tmp"
directory_configs="${directory_entware}/etc"
directory_variable="${directory_entware}/var"
directory_configs_app="${directory_configs}/${name_client}"
directory_app_routing="${directory_configs_app}/dat"
directory_user_settings="${directory_configs_app}/configs"
directory_logs="${directory_variable}/log"
directory_logs_proxy="${directory_logs}/${name_client}"
directory_logs_xkeen="${directory_logs}/xkeen"
directory_ndm="${directory_configs}/ndm"
directory_nefilter="${directory_ndm}/netfilter.d"

# Файлы
file_netfilter_hook="${directory_nefilter}/proxy.sh"
client_xray="${directory_binaries}/xray"
client_hysteria="${directory_binaries}/hysteria"
client_v2fly="${directory_binaries}/v2fy"
client_singbox="${directory_binaries}/singbox"
log_access="${directory_logs}/${name_client}/access.log"
log_error="${directory_logs}/${name_client}/error.log"

# URL
url_server="localhost:79"
url_policy="rci/show/ip/policy"
url_machine="rci/show/defaults"
url_keenetic_port="rci/ip/http/ssl"
url_https_port="rci/ip/static"

# Настройки правил iptables
table_id="111"
table_mark="0x111"
table_redirect="nat"
table_tproxy="mangle"

ipv4_proxy="127.0.0.1"
ipv4_exclude="255.255.255.255/32 0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 192.168.0.0/16 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4"
ipv6_proxy="::1"
ipv6_exclude="::1/128 0000::/8 0100::/64 0200::/7 2001:0002::/48 2001:0010::/28 2001:0db8::/32 2002::/16 3ffe::/16 fc00::/7 fd00::/8 fe80::/10 fec0::/10 ff00::/8 ::ffff:0:0/96 64:ff9b::/96 64:ff9b:1::/48 100::/64 2001::/23"

port_donor=""
port_exclude=""
port_dns="53"

iptables_supported=$(command -v iptables >/dev/null 2>&1 && echo true || echo false)
ip6tables_supported=$(command -v ip6tables >/dev/null 2>&1 && echo true || echo false)


# Настройки запуска
start_attempts=10
start_delay=0
start_auto="off"

# Журналирование
log_info_router() {
    header="$name_app"
    logger -p notice -t "$header" "$1"
}

log_error_router() {
    header="$name_app"
    logger -p error -t "$header" "$1"
}

log_error_terminal() {
    echo
	echo -e "  ${color_red}Ошибка:${color_reset} $1"
    exit 1
}

log_warning_terminal() {
    echo
	echo -e "  ${color_yellow}Предупреждение:${color_reset} $1"
}

log_clean() {
    : > "${log_access}"
	: > "${log_error}"
}

# Определение inbounds
file_inbounds() {
    find "${directory_user_settings}" \
        -name '*.json' \
        -exec grep -lF -m 1 '"inbounds": [' {} \; \
        -quit
}
file_inbounds="$(file_inbounds)"

# Определение DNS
file_dns() {
    find "${directory_user_settings}" \
        -name '*.json' \
        -exec grep -lF -m 1 '"dns": {' {} \; \
        -quit
}
file_dns="$(file_dns)"

create_user() {
	if ! id "xkeen" >/dev/null 2>&1; then
		adduser -D -H -u 11111 -g 11111 xkeen
		sed -i '/^xkeen:/c\xkeen:x:0:11111:::' /opt/etc/passwd
	fi
}

# Обработчик модулей и портов
get_modules() {

	if [ "${mode_proxy}" = "TProxy" ] || [ "${mode_proxy}" = "Mixed_1" ]; then
        module_tproxy="xt_TPROXY.ko"
		module_socket="xt_socket.ko"

        if [ ! -f "${directory_user_modules}/${module_tproxy}" ] && [ ! -f "${directory_os_modules}/${module_tproxy}" ] && ! lsmod | grep -q "${module_tproxy}"; then
            proxy_stop
            log_error_terminal "
  Модуль TProxy не найден
  Невозможно запустить прокси-клиент в режиме TProxy или Mixed без модуля
  Выполните установку компонентов роутера «${color_yellow}IPv6${color_reset}» и «${color_yellow}Модули ядра Netfilter${color_reset}»
"

        if [ ! -f "${directory_user_modules}/${module_socket}" ] && [ ! -f "${directory_os_modules}/${module_socket}" ] && ! lsmod | grep -q "${module_socket}"; then
            proxy_stop
            log_error_terminal "
  Модуль Socket не найден
  Невозможно запустить прокси-клиент в режиме TProxy или Mixed без модуля socket
  Выполните установку компонентов роутера «${color_yellow}IPv6${color_reset}» и «${color_yellow}Модули ядра Netfilter${color_reset}»
"
            return
        fi
    fi

    if [ -n "${port_donor}" ] || [ -n "${port_exclude}" ]; then
        module="xt_multiport.ko"

        if [ ! -f "${directory_user_modules}/${module}" ] && [ ! -f "${directory_os_modules}/${module}" ] && ! lsmod | grep -q "${module}"; then
            log_warning_terminal "
  Модуль multiport не найден
  Невозможно использовать прокси-клиент по выбранным портам или исключить их без модуля
  Выполните установку компонентов роутера «${color_yellow}IPv6${color_reset}» и «${color_yellow}Модули ядра Netfilter${color_reset}»
  
  Прокси-клиент будет запущен на всех портах и без исключений
"
            port_donor=""
            port_exclude=""
        else
            if [ -n "${port_donor}" ]; then
                if [ "$(echo "${port_donor}" | tr ',' '\n' | wc -l)" -gt 15 ]; then
                    log_warning_terminal "
  Количество портов донора прокси-клиента превышает максимум модуля
  Будут оставлены только первые 15 портов
  ${port_donor}
"
                    port_donor=$(echo "${port_donor}" | tr ',' '\n' | head -n 15 | tr '\n' ',')
                    port_donor="${port_donor%,}"
                fi
            fi

            if [ -n "${port_exclude}" ]; then
                if [ "$(echo "${port_exclude}" | tr ',' '\n' | wc -l)" -gt 15 ]; then
                    log_warning_terminal "
  Количество портов исключения прокси-клиента превышает максимум модуля
  Будут оставлены только первые 15 портов
  ${port_exclude}
"
                fi
                port_exclude=$(echo "${port_exclude}" | tr ',' '\n' | head -n 15 | tr '\n' ',')
                port_exclude="${port_exclude%,}"
            fi
        fi
    fi

    if [ -n "${file_dns}" ]; then
        module="xt_owner.ko"

        if [ ! -f "${directory_user_modules}/${module}" ] && [ ! -f "${directory_os_modules}/${module}" ] && ! lsmod | grep -q "${module}"; then
            file_dns=""
            log_warning_terminal "
  Модуль owner не найден.
  Невозможно использовать DNS сервер от прокси-клиента без модуля.
  Выполните установку компонентов роутера «${color_yellow}IPv6${color_reset}» и «${color_yellow}Модули ядра Netfilter${color_reset}».
  
  Прокси-клиент будет запущен с использованием Вашего DNS настроенного на роутере
"
        fi
    fi
fi
}

# Получить порт сервисов keenetic
get_keenetic_port() {
    result=$(curl -kfsS "${url_server}/${url_keenetic_port}")
    keenetic_port=$(
      echo "${result}" |
      jq -r '.port'
    )
	
	if [ "${keenetic_port}" -eq 443 ]; then
		log_error_terminal "
  ${color_red}Порт 443 занят${color_reset} сервисами Keenetic
  Невозможно использовать TProxy не освободив порт
    
  Перейдите в CLI роутера   
  Стандартный адрес
      192.168.1.1/a
	  
  Перенесите сервисы на любой из следующих портов 
      5083 | 5443 | 8083 | 8443 | 65083
  
  Команда переноса
      ip http ssl port {port}
  
  Пример записи
      ip http ssl port 8443
	  
  Сохраните изменения
      system configuration save
"
		proxy_stop
		exit 1
	fi
}

# Получить порт для Redirect
get_port_redirect() {
  for file in $(find "${directory_user_settings}" -name '*.json'); do
    json=$(cat "${file}" | sed 's/\/\/.*$//' | tr -d '[:space:]')
    if [ -n "${json}" ]; then
      #inbounds=$(echo "${json}" | jq -c '.inbounds[] | select(.protocol == "dokodemo-door" and (.tag | contains("dns")) | not)' 2>/dev/null)
      inbounds=$(echo "${json}" | jq -c '.inbounds[] | select(.protocol == "dokodemo-door" and .tag == "redirect")' 2>/dev/null)

      for inbound in ${inbounds}; do
        port=$(echo "${inbound}" | jq -r '.port' 2>/dev/null)
        tproxy=$(echo "${inbound}" | jq -r '.streamSettings.sockopt.tproxy // empty' 2>/dev/null)

        if [ "${tproxy}" != "tproxy" ]; then
          echo "${port}"
          return
        fi
      done
    fi
  done

  echo "${port_redirect}"
}

# Получить порт для TProxy
get_port_tproxy() {
  for file in $(find "${directory_user_settings}" -name '*.json'); do
    json=$(cat "${file}" | sed 's/\/\/.*$//' | tr -d '[:space:]')
    if [ -n "${json}" ]; then
      #inbounds=$(echo "${json}" | jq -c '.inbounds[] | select(.protocol == "dokodemo-door" and (.tag | contains("dns")) | not)' 2>/dev/null)
      inbounds=$(echo "${json}" | jq -c '.inbounds[] | select(.protocol == "dokodemo-door" and .tag == "tproxy")' 2>/dev/null)

      for inbound in ${inbounds}; do
        port=$(echo "${inbound}" | jq -r '.port' 2>/dev/null)
        tproxy=$(echo "${inbound}" | jq -r '.streamSettings.sockopt.tproxy // empty' 2>/dev/null)

        if [ "${tproxy}" == "tproxy" ]; then
          echo "${port}"
          return
        fi
      done
    fi
  done

  echo "${port_tproxy}"
}

# Получить сеть для Redirect
get_network_redirect() {
  for file in $(find "${directory_user_settings}" -name '*.json'); do
    json=$(cat "${file}" | sed 's/\/\/.*$//' | tr -d '[:space:]')
    if [ -n "${json}" ]; then
      #inbounds=$(echo "${json}" | jq -c '.inbounds[] | select(.protocol == "dokodemo-door" and (.tag | contains("dns")) | not)' 2>/dev/null)
      inbounds=$(echo "${json}" | jq -c '.inbounds[] | select(.protocol == "dokodemo-door" and .tag == "redirect")' 2>/dev/null)

      for inbound in ${inbounds}; do
        network=$(echo "${inbound}" | jq -r '.settings.network' 2>/dev/null | tr -d '[:space:]' | tr ',' ' ')
        tproxy=$(echo "${inbound}" | jq -r '.streamSettings.sockopt.tproxy // empty' 2>/dev/null)

        if [ "${tproxy}" != "tproxy" ]; then
          echo "${network}"
          return
        fi
      done
    fi
  done

  echo "${network_redirect}"
}

# Получить сеть для TProxy
get_network_tproxy() {
  for file in $(find "${directory_user_settings}" -name '*.json'); do
    json=$(cat "${file}" | sed 's/\/\/.*$//' | tr -d '[:space:]') 
    if [ -n "${json}" ]; then
      #inbounds=$(echo "${json}" | jq -c '.inbounds[] | select(.protocol == "dokodemo-door" and (.tag | contains("dns")) | not)' 2>/dev/null)
      inbounds=$(echo "${json}" | jq -c '.inbounds[] | select(.protocol == "dokodemo-door" and .tag == "tproxy")' 2>/dev/null)

      for inbound in ${inbounds}; do
        network=$(echo "${inbound}" | jq -r '.settings.network' 2>/dev/null | tr -d '[:space:]' | tr ',' ' ')
        tproxy=$(echo "${inbound}" | jq -r '.streamSettings.sockopt.tproxy // empty' 2>/dev/null)

        if [ "${tproxy}" == "tproxy" ]; then
          echo "${network}"
          return
        fi
      done
    fi
  done

  echo "${network_tproxy}"
}

# Исключить порты переадресации
get_port_exclude() {
    result=$(curl -kfsS "${url_server}/${url_https_port}")
    port_exclude_redirect=$(
        echo "${result}" | 
        jq -r '
          .[] | 
          if has("to-port") then .["to-port"] else .port end' |
        grep -E -v '(^|,)80($|,)|(^|,)443($|,)' |
        tr '\n' ',' |
        sed 's/,$//'
    )	

    if [ -n "${port_exclude_redirect}" ]; then
        if [ -z "${port_exclude}" ]; then
            port_exclude="${port_exclude_redirect}"
        else
            port_exclude="${port_exclude},${port_exclude_redirect}"
        fi
    fi

    port_exclude=$(echo "${port_exclude}" | 
        tr -dc '0-9,' |
        sed 's/,,*/,/g; s/^,//; s/,$//'
    )
    
    echo "${port_exclude}"
}

# Получить IPv4
get_exclude_ip4() {
    if [ "$iptables_supported" = true ]; then
        ipv4_eth=$(ip route get 77.88.8.8 | awk '/src/ {print $NF}' ||
                   ip route get 8.8.8.8 | awk '/src/ {print $NF}' ||
                   ip route get 1.1.1.1 | awk '/src/ {print $NF}'
		)

        [ -n "$ipv4_eth" ] && ipv4_eth="${ipv4_eth}/32 "

        ipv4_my=$(echo "${ipv4_eth}${ipv4_exclude}" | tr -s ' ')
        echo "$ipv4_my"
    fi
}

# Получить IPv6
get_exclude_ip6() {
    if [ "$ip6tables_supported" = true ]; then
        ipv6_eth=$(ip -6 route get 2a02:6b8::feed:0ff | awk '/src/ {print $NF}' || 
                   ip -6 route get 2001:4860:4860::8888 | awk '/src/ {print $NF}' || 
                   ip -6 route get 2606:4700:4700::1111 | awk '/src/ {print $NF}'
        )

        [ -n "$ipv6_eth" ] && ipv6_eth="${ipv6_eth}/128 "

        ipv6_my=$(echo "${ipv6_eth}${ipv6_exclude}" | tr -s ' ')
        echo "$ipv6_my"
    fi
}

# Получить данные политики
get_policy_mark() {
    policy_mark=$(
        curl -kfsS "${url_server}/${url_policy}" \
        | jq -r '
            .[]
            | select(.description
            | ascii_downcase == "'"${name_policy}"'")
			| .mark'
    )

	if ! proxy_status && [ -z "${policy_mark}" ]; then
			if [ -z "${port_donor}" ]; then
				log_warning_terminal "
  Отсутствует политика «${color_green}XKeen${color_reset}» в Web роутера
  Не определены целевые порты для XKeen
  Клиент ${name_client} ${green_red}будет${color_reset} запущен для всего устройства
	  " >&2
				echo ""
			else
				log_warning_terminal "
  Отсутствует политика «${color_green}XKeen${color_reset}» в Web роутера
  Найдены целевые порты для XKeen
  ${name_client} будет запущен для всего устройства на портах ${port_donor}
	  " >&2
				echo ""
			fi
    else
        echo "0x${policy_mark}"
    fi
}

# Получить режим прокси-клиента
get_mode_proxy() {
	if [ -n "${port_redirect}" ] && [ -n "${port_tproxy}" ]; then
		mode_proxy="Mixed_1"
		log_info_router "${name_client} запущен в режиме ${mode_proxy}"
	elif [ -n "${port_tproxy}" ]; then
		mode_proxy="TProxy"
		log_info_router "${name_client} запущен в режиме ${mode_proxy}"
	elif [ -n "${port_redirect}" ]; then
		mode_proxy="Redirect"
		log_info_router "${name_client} запущен в режиме ${mode_proxy}"
	else
		mode_proxy="Other"
		log_info_router "${name_client} запущен в обычном режиме"
		log_info_router "Для работы ${name_client} нужно направить на него соединение любым удобным Вам способом"
	fi

	echo "${mode_proxy}"
}

# Добавление правил Iptables
configure_firewall() {
    if [ ! -f "${file_netfilter_hook}" ]; then
        touch "${file_netfilter_hook}"
    fi
	
	: > "${file_netfilter_hook}"

    cat >"${file_netfilter_hook}" <<EOL
#!/bin/sh

name_client="${name_client}"
name_profile="${name_profile}"
name_client="${name_client}"

mode_proxy="${mode_proxy}"
network_redirect="${network_redirect}"
network_tproxy="${network_tproxy}"
networks="${networks}"

name_prerouting_chain="${name_prerouting_chain}"
name_output_chain="${name_output_chain}"
name_profile="${name_profile}"
port_redirect="${port_redirect}"
port_tproxy="${port_tproxy}"
port_donor="${port_donor}"
port_exclude="${port_exclude}"
port_dns="${port_dns}"

multiport_option=""
policy_mark="${policy_mark}"
table_redirect="${table_redirect}"
table_tproxy="${table_tproxy}"
table_mark="${table_mark}"
table_id="${table_id}"

file_dns="${file_dns}"
directory_os_modules=${directory_os_modules}
directory_user_modules=${directory_user_modules}
directory_app_routing="${directory_app_routing}"
directory_user_settings="${directory_user_settings}"

iptables_supported=${iptables_supported}
ip6tables_supported=${ip6tables_supported}


restart_script() {
    exec /bin/sh "\$0" "\$@"
}

if busybox ps | grep -v grep | grep "\${name_client} run" > /dev/null
then

	# Загружаем модули
	load_modules() {
		local module="\${1}"
		local module_loaded=false

		if [ -f "\${directory_user_modules}/\${module}" ]; then
			insmod "\${directory_user_modules}/\${module}" >/dev/null 2>&1
			module_loaded=true
		else
			if [ -f "\${directory_os_modules}/\${module}" ]; then
				insmod "\${directory_os_modules}/\${module}" >/dev/null 2>&1
				module_loaded=true
			fi
		fi

		if [ "\${module_loaded}" = false ]; then
			if ! lsmod | grep -q "\${module}"; then
				case "\${module}" in
					"xt_owner.ko")
						file_dns=""
						;;
					"xt_multiport.ko")
						port_exclude=""
						port_donor=""
						;;
				esac
			fi
		fi
	}

	# Функция создания цепи и правил
	add_ipt_rule() {
		local family="\${1}"
		local table="\${2}"
		local chain="\${3}"
		shift 3

		if { [ "\${family}" = "iptables" ] && [ "\${iptables_supported}" = "false" ]; } || { [ "\${family}" = "ip6tables" ] && [ "\${ip6tables_supported}" = "false" ]; }; then
			return
		fi

		if ! "\${family}" -t "\${table}" -nL \${name_prerouting_chain} >/dev/null 2>&1; then
			"\${family}" -t "\${table}" -N \${name_prerouting_chain} || exit 0
			add_exclude_rules \${name_prerouting_chain}
			
			case "\${mode_proxy}" in
				"Mixed_1")
					if [ "\${table}" = "\${table_redirect}" ]; then
						"\${family}" -w -t "\${table}" -A \${name_prerouting_chain} -p tcp -j REDIRECT --to-port "\${port_redirect}" >/dev/null 2>&1
					else
						load_modules xt_TPROXY.ko
						"\${family}" -w -t "\${table}" -I \${name_prerouting_chain} -p udp -m socket --transparent -j MARK --set-mark "\${table_mark}" >/dev/null 2>&1
						"\${family}" -w -t "\${table}" -A \${name_prerouting_chain} -p udp -j TPROXY --on-ip "\${proxy_ip}" --on-port "\${port_tproxy}" --tproxy-mark "\${table_mark}" >/dev/null 2>&1
					fi
					;;
				"TProxy")
					load_modules xt_TPROXY.ko
					for net in \${network_tproxy}; do
						"\${family}" -w -t "\${table}" -I \${name_prerouting_chain} -p "\${net}" -m socket --transparent -j MARK --set-mark "\${table_mark}" >/dev/null 2>&1
						"\${family}" -w -t "\${table}" -A \${name_prerouting_chain} -p "\${net}" -j TPROXY --on-ip "\${proxy_ip}" --on-port "\${port_tproxy}" --tproxy-mark "\${table_mark}" >/dev/null 2>&1
					done    
					;;
				"Redirect")
					for net in \${network_redirect}; do
						"\${family}" -w -t "\${table}" -A \${name_prerouting_chain} -p "\${net}" -j REDIRECT --to-port "\${port_redirect}" >/dev/null 2>&1
					done
					;;
				*)
					exit 0
					;;
			esac        
		fi

		if [ "\${table}" = "\${table_tproxy}" ]; then
			if ! "\${family}" -t "\${table}" -nL \${name_output_chain} >/dev/null 2>&1; then
				"\${family}" -t "\${table}" -N \${name_output_chain} || exit 0
				add_exclude_rules \${name_output_chain}
		
				for net in \${network_tproxy}; do
					"\${family}" -w -t "\${table}" -A \${name_output_chain} -p "\${net}" -j CONNMARK --set-mark "\${table_mark}" >/dev/null 2>&1
				done
			fi
		fi
	}

	# Добавление правил-исключений
	add_exclude_rules() {
		local chain="\${1}"

		for exclude in \${exclude_list}; do
			if [ "\${exclude}" = "192.168.0.0/16" ] && [ "\${chain}" != "\${name_output_chain}" ] && [ -n "\${file_dns}" ] || [ "\${exclude}" = "fd00::/8" ] && [ "\${chain}" != "\${name_output_chain}" ] && [ -n "\${file_dns}" ]; then
				if [ -n "\${file_dns}" ]; then
					if [ "\${table}" = "mangle" ] && [ "\${mode_proxy}" = "Mixed_1" ]; then
						"\${family}" -w -t "\${table}" -A "\${chain}" -d "\${exclude}" -p tcp --dport "\${port_dns}" -j RETURN >/dev/null 2>&1
						"\${family}" -w -t "\${table}" -A "\${chain}" -d "\${exclude}" -p udp ! --dport "\${port_dns}" -j RETURN >/dev/null 2>&1
					elif [ "\${table}" = "nat" ] && [ "\${mode_proxy}" = "Mixed_1" ]; then
						"\${family}" -w -t "\${table}" -A "\${chain}" -d "\${exclude}" -p tcp ! --dport "\${port_dns}" -j RETURN >/dev/null 2>&1
						"\${family}" -w -t "\${table}" -A "\${chain}" -d "\${exclude}" -p udp --dport "\${port_dns}" -j RETURN >/dev/null 2>&1
					elif [ "\${table}" = "mangle" ] && [ "\${mode_proxy}" = "TProxy" ]; then
						"\${family}" -w -t "\${table}" -A "\${chain}" -d "\${exclude}" -p tcp ! --dport "\${port_dns}" -j RETURN >/dev/null 2>&1
						"\${family}" -w -t "\${table}" -A "\${chain}" -d "\${exclude}" -p udp ! --dport "\${port_dns}" -j RETURN >/dev/null 2>&1
					fi
				fi
			else
				"\${family}" -w -t "\${table}" -A "\${chain}" -d "\${exclude}" -j RETURN >/dev/null 2>&1
			fi
		done
	}

	# Создание таблицы маршрутов
	configure_route() {
		local ip_version="\${1}"
		if ! busybox ip -"\${ip_version}" rule show | grep -q "fwmark \${table_mark} lookup \${table_id}" >/dev/null 2>&1; then
			if [ -n "\${policy_mark}" ]; then
				policy_table=\$(busybox ip rule show | awk -v policy="\${policy_mark}" '\$0 ~ policy && /lookup/ && !/blackhole/{print \$NF}')
			fi

			busybox ip -"\${ip_version}" rule add fwmark "\${table_mark}" lookup "\${table_id}" >/dev/null 2>&1
			busybox ip -"\${ip_version}" route add local default dev lo table "\${table_id}" >/dev/null 2>&1

			if [ -n "\${policy_table}" ]; then
				busybox ip -"\${ip_version}" route show table "\${policy_table}" | grep -Ev '^default' | 
				while read -r route; do 
					matching_main_route=\$(busybox ip -"\${ip_version}" route show table main | grep -F "\${route}")
					busybox ip -"\${ip_version}" route add table "\${table_id}" \${matching_main_route} >/dev/null 2>&1
				done
			else
				busybox ip -"\${ip_version}" route show table main | grep -Ev '^default' | 
				while read -r route; do 
					busybox ip -"\${ip_version}" route add table "\${table_id}" \${route} >/dev/null 2>&1
				done
			fi
		fi
	}

	# Добавление цепей
	add_prerouting() {
		local family="\${1}"
		local active_table="\${2}"

		for net in \${networks}; do
			if [ "\${mode_proxy}" = "Mixed_1" ]; then
				case "\${net}" in
					"tcp")
						active_table="nat"
						if [ "\${family}" = "iptables" ] && [ "\${iptables_supported}" = "true" ] && ! iptables -t "\${active_table}" -C PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p tcp \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1; then
							iptables -t "\${active_table}" -A PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p tcp \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1
						fi
						if [ "\${family}" = "ip6tables" ] && [ "\${ip6tables_supported}" = "true" ] && ! ip6tables -t "\${active_table}" -C PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p tcp \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1; then
							ip6tables -t "\${active_table}" -A PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p tcp \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1
						fi
						;;
					"udp")
						active_table="mangle"
						if [ "\${family}" = "iptables" ] && [ "\${iptables_supported}" = "true" ] && ! iptables -t "\${active_table}" -C PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p udp \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1; then
							iptables -t "\${active_table}" -A PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p udp \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1
						fi
						if [ "\${family}" = "ip6tables" ] && [ "\${ip6tables_supported}" = "true" ] && ! ip6tables -t "\${active_table}" -C PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p udp \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1; then
							ip6tables -t "\${active_table}" -A PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p udp \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1
						fi
						;;
					*)
						exit 0
						;;
				esac
			else
				if [ -n "\${multiport_option}" ]; then
					for family in iptables ip6tables; do
						if [ "\${family}" = "iptables" ] && [ "\${iptables_supported}" = "true" ] && ! iptables -t "\${active_table}" -C PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p \${net} \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1; then
							iptables -t "\${active_table}" -A PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p \${net} \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1
						fi

						if [ "\${family}" = "ip6tables" ] && [ "\${ip6tables_supported}" = "true" ] && ! ip6tables -t "\${active_table}" -C PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p \${net} \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1; then
							ip6tables -t "\${active_table}" -A PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -p \${net} \${multiport_option} -j \${name_prerouting_chain} >/dev/null 2>&1
						fi
					done
				else
					for family in iptables ip6tables; do
						if [ "\${family}" = "iptables" ] && [ "\${iptables_supported}" = "true" ] && ! iptables -t "\${active_table}" -C PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -j \${name_prerouting_chain} >/dev/null 2>&1; then
							iptables -t "\${active_table}" -A PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -j \${name_prerouting_chain} >/dev/null 2>&1
						fi

						if [ "\${family}" = "ip6tables" ] && [ "\${ip6tables_supported}" = "true" ] && ! ip6tables -t "\${active_table}" -C PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -j \${name_prerouting_chain} >/dev/null 2>&1; then
							ip6tables -t "\${active_table}" -A PREROUTING \${connmark_option} -m conntrack ! --ctstate INVALID -j \${name_prerouting_chain} >/dev/null 2>&1
						fi
					done
				fi
			fi
		done
	}

	# Добавление цепей
	add_output() {
		local family="\${1}"
		local active_table="\${2}"

		if [ "\${mode_proxy}" = "TProxy" ]; then
			for family in iptables ip6tables; do
				if [ "\${family}" = "iptables" ] && ! iptables -t "\${active_table}" -C OUTPUT -m owner ! --uid-owner \${name_profile} -m conntrack ! --ctstate INVALID ! -p icmp -j \${name_output_chain} >/dev/null 2>&1; then
					iptables -t "\${active_table}" -A OUTPUT -m owner ! --uid-owner \${name_profile} -m conntrack ! --ctstate INVALID ! -p icmp -j \${name_output_chain} >/dev/null 2>&1
				fi
				if [ "\${family}" = "ip6tables" ] && ! ip6tables -t "\${active_table}" -C OUTPUT -m owner ! --uid-owner \${name_profile} -m conntrack ! --ctstate INVALID ! -p icmp -j \${name_output_chain} >/dev/null 2>&1; then
					ip6tables -t "\${active_table}" -A OUTPUT -m owner ! --uid-owner \${name_profile} -m conntrack ! --ctstate INVALID ! -p icmp -j \${name_output_chain} >/dev/null 2>&1
				fi
			done
		fi

		if [ "\${mode_proxy}" = "Mixed_1" ]; then
			for family in iptables ip6tables; do
				if [ "\${family}" = "iptables" ] && ! iptables -t "\${active_table}" -C OUTPUT -m owner ! --uid-owner \${name_profile} -m conntrack ! --ctstate INVALID -p udp -j \${name_output_chain} >/dev/null 2>&1; then
					iptables -t "\${active_table}" -A OUTPUT -m owner ! --uid-owner \${name_profile} -m conntrack ! --ctstate INVALID -p udp -j \${name_output_chain} >/dev/null 2>&1
				fi
				if [ "\${family}" = "ip6tables" ] && ! ip6tables -t "\${active_table}" -C OUTPUT -m owner ! --uid-owner \${name_profile} -m conntrack ! --ctstate INVALID -p udp -j \${name_output_chain} >/dev/null 2>&1; then
					ip6tables -t "\${active_table}" -A OUTPUT -m owner ! --uid-owner \${name_profile} -m conntrack ! --ctstate INVALID -p udp -j \${name_output_chain} >/dev/null 2>&1
				fi
			done
		fi
	}

	# Определение дополнительных переменных и инициация функций
	[ -n "\${policy_mark}" ] && connmark_option="-m connmark --mark \${policy_mark}"

	if [ -n "\${port_donor}" ] || [ -n "\${port_exclude}" ]; then
		load_modules xt_multiport.ko
		[ -n "\${file_dns}" ] && [ -n "\${port_donor}" ] && port_donor="\${port_dns},\${port_donor}"
		[ -n "\${port_donor}" ] && multiport_option="-m multiport --dports \${port_donor}"
		[ -n "\${port_exclude}" ] && [ -z "\${port_donor}" ] && multiport_option="-m multiport ! --dports \${port_exclude}"
	fi

	for family in iptables ip6tables; do
		if [ "\${family}" = "ip6tables" ]; then
			exclude_list="$(get_exclude_ip6)"
			proxy_ip="${ipv6_proxy}"
			configure_route 6
		else
			exclude_list="$(get_exclude_ip4)"
			proxy_ip="${ipv4_proxy}"
			configure_route 4
		fi

		if [ -n "\${port_redirect}" ] && [ -n "\${port_tproxy}" ]; then
			for active_table in "\${table_tproxy}" "\${table_redirect}"; do
				add_ipt_rule "\${family}" "\${active_table}" "\${name_prerouting_chain}"
				add_prerouting "\${family}" "\${active_table}"
			done
		elif [ -z "\${port_redirect}" ] && [ -n "\${port_tproxy}" ]; then
			active_table="\${table_tproxy}"
			add_ipt_rule "\${family}" "\${active_table}" "\${name_prerouting_chain}"
			add_prerouting "\${family}" "\${active_table}"
		elif [ -n "\${port_redirect}" ] && [ -z "\${port_tproxy}" ]; then
			active_table="\${table_redirect}"
			add_ipt_rule "\${family}" "\${active_table}" "\${name_prerouting_chain}"
			add_prerouting "\${family}" "\${active_table}"
		fi

		if [ "\${mode_proxy}" != "Redirect" ]; then
			load_modules xt_socket.ko
			load_modules xt_owner.ko
			add_ipt_rule "\${family}" "\${table_tproxy}" "\${name_output_chain}"
			add_output "\${family}" "\${table_tproxy}"
		fi
	done
else
	export XRAY_LOCATION_ASSET="\${directory_app_routing}"
	export XRAY_LOCATION_CONFDIR="\${directory_user_settings}"
	if [ "\${mode_proxy}" != "Redirect" ] || [ "\${mode_proxy}" != "Other" ]; then
		ulimit -SHn 1000000 && exec su -c "\${name_client} run" "\${name_profile}" &
	else
		"\${name_client}" run &
	fi

    sleep 5

    restart_script "\$@"
fi

EOL

	chmod +x "${file_netfilter_hook}"
	sh "${file_netfilter_hook}"
}

directory_configs_clean() {
    if [ -d "$directory_user_settings" ]; then
        find "$directory_user_settings" -type f -name ".*" -exec rm -f {} \; > /dev/null 2>&1
    fi
}

# Удаление правил Iptables
clean_firewall() {
	    : > "${file_netfilter_hook}"
		
		clean_run() {
			local family="${1}"
			local active_table="${2}"
			local name_chain="${3}"

			for family in iptables ip6tables; do
				if command -v "${family}" >/dev/null 2>&1; then
					if ${family} -t "${active_table}" -nL ${name_prerouting_chain} >/dev/null 2>&1; then
						${family} -t "${active_table}" -F ${name_prerouting_chain} >/dev/null 2>&1
						while ${family} -w -t "${active_table}" -nL PREROUTING | grep -q "${name_prerouting_chain}"; do
							rule_number=$(${family} -w -t "${active_table}" -nL PREROUTING --line-numbers | grep -v "Chain" | grep -m 1 "${name_prerouting_chain}" | awk '{print $1}')
							${family} -w -t "${active_table}" -D PREROUTING "${rule_number}" >/dev/null 2>&1
						done
						${family} -w -t "${active_table}" -X ${name_prerouting_chain} >/dev/null 2>&1
					fi

					if ${family} -t "${active_table}" -nL ${name_output_chain} >/dev/null 2>&1; then
						${family} -t "${active_table}" -F ${name_output_chain} >/dev/null 2>&1
						while ${family} -w -t "${active_table}" -nL OUTPUT | grep -q "${name_output_chain}"; do
							rule_number=$(${family} -w -t "${active_table}" -nL OUTPUT --line-numbers | grep -v "Chain" | grep -m 1 "${name_output_chain}" | awk '{print $1}')
							${family} -w -t "${active_table}" -D OUTPUT "${rule_number}" >/dev/null 2>&1
						done
						${family} -w -t "${active_table}" -X ${name_output_chain} >/dev/null 2>&1
					fi
				fi
			done
		}

    for table in iptables ip6tables; do
        for chain in nat mangle; do
			clean_run "${table}" "${chain}" "${name_prerouting_chain}"
            clean_run "${table}" "${chain}" "${name_output_chain}"
        done
    done

    for family in 4 6; do
        if command -v busybox ip >/dev/null 2>&1 && busybox ip -"${family}" rule show | grep -q "fwmark ${table_mark} lookup ${table_id}" >/dev/null 2>&1; then
            busybox ip -"${family}" rule del fwmark ${table_mark} lookup ${table_id} >/dev/null 2>&1
            busybox ip -"${family}" route flush table ${table_id} >/dev/null 2>&1
        fi
    done
}

# Проверка статуса прокси-клиента
proxy_status() {
    busybox ps | grep -v grep | grep "${name_client} run" >/dev/null 2>&1
}

# Запуск прокси-клиента
proxy_start() {
	local start_manual=${1}
    if [ "${start_manual}" = "on" -o "${start_auto}" = "on" ]; then
        log_info_router "Инициирован запуск прокси-клиента"
		log_clean
		directory_configs_clean
		port_redirect=$(get_port_redirect)
		network_redirect=$(get_network_redirect)
		port_tproxy=$(get_port_tproxy)
		network_tproxy=$(get_network_tproxy)
		mode_proxy=$(get_mode_proxy)		
		if [ "${mode_proxy}" != "Other" ]; then
			policy_mark=$(get_policy_mark)
			networks=$(echo "${network_redirect} ${network_tproxy}" | tr ',' ' ' | tr -s ' ' | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/^ //; s/ $//')
			if [ -n "${policy_mark}" ] && [ -z "${port_donor}" ]; then
				port_exclude=$(get_port_exclude)
			fi
			if ! proxy_status && ( [ -n "${port_donor}" ] || [ -n "${port_exclude}" ] || [ "${mode_proxy}" = "TProxy" ] || [ "${mode_proxy}" = "Mixed_1" ] ); then
				get_modules
			fi
			if [ "${mode_proxy}" = "TProxy" ] || [ "${mode_proxy}" = "Mixed_1" ]; then
				get_keenetic_port
			fi
		fi
		
        if proxy_status; then
            echo -e "  Прокси-клиент уже ${color_green}запущен${color_reset}"
            log_error_terminal "Не удалось запустить Xray, так как он уже запущен"
        else
            local delay_increment=1
            local current_delay=${start_delay}

            for attempt_number in $(seq 1 ${start_attempts}); do
				
				case "${name_client}" in
				xray)
				export XRAY_LOCATION_ASSET="${directory_app_routing}"
				export XRAY_LOCATION_CONFDIR="${directory_user_settings}"
				if [ "${mode_proxy}" != "Redirect" ] || [ "${mode_proxy}" != "Other" ]; then
					create_user
					ulimit -SHn 1000000 && exec su -c "${name_client} run" "${name_profile}" &
				else
					"${name_client}" run &
				fi
					;;
				*)
				"${name_client}" run -C "${directory_user_settings}" &
					;;
				esac
				
                sleep ${current_delay}
                if ! proxy_status; then
                    current_delay=$((current_delay + delay_increment))
                    continue
                fi
				if [ "${mode_proxy}" != "Other" ]; then
					configure_firewall
				fi
				echo -e "  Прокси-клиент ${color_green}запущен${color_reset}"
				log_info_router "Прокси-клиент запущен"
                return 0
            done
            echo -e "  Прокси-клиент ${color_red}не запустить${color_reset}"
            log_error_terminal "Не удалось запустить прокси-клиент"
            exit 1
        fi
    else
        clean_firewall
        exit 0
    fi
}

# Остановка прокси-клиента
proxy_stop() {
    log_info_router "Инициирована остановка прокси-клиента"	
    if ! proxy_status; then
        echo -e "  Прокси-клиент ${color_red}не запущен${color_reset}"
    else
        local delay_increment=1
        local current_delay=${start_delay}

        for attempt_number in $(seq 1 ${start_attempts}); do
			clean_firewall
            busybox killall -q -9 "${name_client}"
			sleep ${current_delay}
            if proxy_status; then
                current_delay=$((current_delay + delay_increment))
                continue
            fi
            echo -e "  Прокси-клиент ${color_yellow}остановлен${color_reset}"
            log_info_router "Прокси-клиент остановлен"
            return 0
        done
        echo -e "  Прокси-клиент ${color_red}не остановлен${color_reset}"
        log_error_terminal "Не удалось остановить прокси-клиент"
    fi
}

# Менеджер команд
case "${1}" in
start)
    proxy_start ${2}
    ;;
stop)
    proxy_stop
    ;;
status)
	if proxy_status; then
		echo -e "  Прокси-клиент ${color_green}запущен${color_reset}"
	else
		echo -e "  Прокси-клиент ${color_red}не запущен${color_reset}"
	fi
    ;;
restart)
    proxy_stop
    proxy_start ${2}
    ;;
*)
    echo -e "  Команды: ${color_green}start${color_reset} | ${color_red}stop${color_reset} | ${color_yellow}restart${color_reset} | status"
    ;;
esac

exit 0
