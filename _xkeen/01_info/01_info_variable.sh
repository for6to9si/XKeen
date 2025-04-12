# -------------------------------------
# Цвета
# -------------------------------------
green="\033[32m"      # Зеленый
red="\033[31m"        # Красный
yellow="\033[33m"     # Желтый
light_blue="\033[96m" # Голубой
dark_gray="\e[90m"    # Темно-серый
reset="\033[0m"       # Сброс цветов

# -------------------------------------
# Директории
# -------------------------------------
tmp_dir_global="/opt/tmp"            # Временная директория общая
tmp_dir="/opt/tmp/xkeen"             # Временная директория xkeen
xkeen_log_dir="/opt/var/log/xkeen"   # Директория логов для xkeen
xray_log_dir="/opt/var/log/xray"     # Директория логов для xray
initd_dir="/opt/etc/init.d"          # Директория init.d
pid_dir="/opt/var/run"               # Директория для pid файлов
backups_dir="/opt/backups"           # Директория для бекапов
install_dir="/opt/sbin"              # Директория установки
xkeen_dir="/opt/sbin/.xkeen"        # xkeen директория
geo_dir="/opt/etc/xray/dat"          # Директория для dat
cron_dir="/opt/var/spool/cron/crontabs" # Директория для cron файла xkeen
cron_file="root"                    # Сron файл
install_conf_dir="/opt/etc/xray/configs"  # Директория для хранения конфигурации в xray
xkeen_conf_dir="$xkeen_dir/02_install/08_install_configs/02_configs_dir/" # Директория для хранения конфигурации в xkeen
register_dir="/opt/lib/opkg/info"
status_file="/opt/lib/opkg/status"
releases_dir="/opt/releases"
os_modules="/lib/modules/$(uname -r)"
user_modules="/opt/lib/modules"
app_name=XKeen
xkeen_current_version="1.1.3"
init_current_verison="2.19"

# -------------------------------------
# Время
# -------------------------------------
installed_time=$(date +%s)
existing_content=$(cat "$status_file")
installed_size=$(du -s "$install_dir" | cut -f1)
source_date_epoch=$(date +%s)
current_datetime=$(date "+%d-%b-%y_%H-%M")

# -------------------------------------
# API URL
# -------------------------------------
xray_api_url="https://api.github.com/repos/XTLS/Xray-core/releases/tags/v1.8.4"  # url api для xray
xkeen_api_url="https://api.github.com/repos/skrill0/xkeen/releases/latest"	# url api для xkeen

# -------------------------------------
# Создание директорий и файлов
# -------------------------------------
mkdir -p "$xkeen_log_dir" || { echo "Ошибка: Не удалось создать директорию $xkeen_log_dir"; exit 1; }
mkdir -p "$xray_log_dir" || { echo "Ошибка: Не удалось создать директорию $xray_log_dir"; exit 1; }
mkdir -p "$initd_dir" || { echo "Ошибка: Не удалось создать директорию $initd_dir"; exit 1; }
mkdir -p "$pid_dir" || { echo "Ошибка: Не удалось создать директорию $pid_dir"; exit 1; }
mkdir -p "$backups_dir" || { echo "Ошибка: Не удалось создать директорию $backups_dir"; exit 1; }
mkdir -p "$install_dir" || { echo "Ошибка: Не удалось создать директорию $install_dir"; exit 1; }
mkdir -p "$cron_dir" || { echo "Ошибка: Не удалось создать директорию $cron_dir"; exit 1; }

# -------------------------------------
# Журналы
# -------------------------------------
xkeen_info_log="$xkeen_log_dir/info.log"
xkeen_error_log="$xkeen_log_dir/error.log"

xray_access_log="$xray_log_dir/access.log"
xray_error_log="$xray_log_dir/error.log"

touch "$xkeen_info_log" || { echo "Ошибка: Не удалось создать файл $xkeen_info_log"; exit 1; }
touch "$xkeen_error_log" || { echo "Ошибка: Не удалось создать файл $xkeen_error_log"; exit 1; }

touch "$xray_access_log" || { echo "Ошибка: Не удалось создать файл $xkeen_info_log"; exit 1; }
touch "$xray_error_log" || { echo "Ошибка: Не удалось создать файл $xkeen_error_log"; exit 1; }

# -------------------------------------
# Вызов API
# -------------------------------------

call_api() {
    local url="$1"
    local response

    response=$(curl -ss "$url")
    if [ $? -ne 0 ]; then
        log_error "Ошибка при вызове api: $url"
        exit 1
    fi

    echo "$response"
}

log_notice(){
    local header=${app_name}
    logger -p notice -t "${header}" "${1}"
}
