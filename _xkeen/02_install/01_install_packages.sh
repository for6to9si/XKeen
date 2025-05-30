# Установка необходимых пакетов
install_packages() {
    # Определение переменных
    local package_status="$1"
    local package_name="$2"

    # Проверка статуса пакета
    if [ "${package_status}" = "not_installed" ]; then
        # Установка пакета
        opkg install "${package_name}" &>/dev/null

        # Проверка успешности установки
        if [ $? -eq 0 ]; then
            package_status="installed_xkeen"
        fi
    fi
}

install_packages "$info_packages_lscpu" "lscpu"
install_packages "$info_packages_curl" "curl"
install_packages "$info_packages_jq" "jq"
install_packages "$info_packages_libc" "libc"
install_packages "$info_packages_libssp" "libssp"
install_packages "$info_packages_librt" "librt"
install_packages "$info_packages_iptables" "iptables"
install_packages "$info_packages_libpthread" "libpthread"

install_packages "$info_packages_cabundle" "ca-bundle"
info_packages_cabundle="$package_status"
install_packages "$info_packages_uname" "coreutils-uname"
info_packages_uname="$package_status"
install_packages "$info_packages_nohup" "coreutils-nohup"
info_packages_nohup="$package_status"