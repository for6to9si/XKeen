
diagnostic() {
# Установка пути к файлу diagnostic
diagnostic="/opt/diagnostic.txt"
echo "  Диагностика началась"
echo "  Пожалуйста, дождитесь уведомления о окончании"

# Создаем файл diagnostic
touch "$diagnostic" 

# Очищаем файл diagnostic перед записью новых данных
> "$diagnostic" 

# Функция для записи заголовка в файл
write_header() {
    echo "-------------------------" >> "$diagnostic"
    echo "$1" >> "$diagnostic"
    echo "-------------------------" >> "$diagnostic"
    echo "" >> "$diagnostic"
}

if busybox ps | grep -v grep | grep "${name_client} run" >/dev/null 2>&1
then

# 2. Запись заголовка и выполнение команд iptables
write_header "Результат таблицы NAT цепи PREROUTING"
{ iptables -t nat -nvL PREROUTING 2>&1; } >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

write_header "Результат таблицы NAT цепи xkeen"
{ iptables -t nat -nvL xkeen 2>&1; } >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

write_header "Результат таблицы MANGLE цепи PREROUTING"
{ iptables -t mangle -nvL PREROUTING 2>&1; } >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

write_header "Результат таблицы MANGLE цепи xkeen"
{ iptables -t mangle -nvL xkeen 2>&1; } >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

write_header "Результат таблицы MANGLE цепи OUTPUT"
{ iptables -t mangle -nvL OUTPUT 2>&1; } >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

write_header "Результат таблицы MANGLE цепи xkeen_mask"
{ iptables -t mangle -nvL xkeen_mask 2>&1; } >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 3. Копирование содержимого файла /opt/etc/ndm/netfilter.d/proxy.sh
write_header "Содержимое файла /opt/etc/ndm/netfilter.d/proxy.sh"
cat /opt/etc/ndm/netfilter.d/proxy.sh >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 4. Проверка использования SSL порта
write_header "Проверка использования SSL порта"
curl -kfsS "localhost:79/rci/ip/http/ssl" | jq -r '.port' >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 5. Сбор данных о политике доступа
write_header "Данные о политике доступа"
curl -kfsS "localhost:79/rci/show/ip/policy" | jq -r ' .[] | select(.description | ascii_downcase == "xkeen")' >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 6. Сбор результатов команды ip rule show
write_header "Результат команды ip rule show"
ip rule show >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 7. Сбор результатов команды ip route show table main
write_header "Результат команды ip route show table main"
ip route show table main >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 8. Определение IP адреса с использованием запроса на внешний сервер
write_header "Внешний IP адрес"
external_ip=$(curl -s ifconfig.me)
echo "${external_ip}" >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 9. Запрос к curl для получения country, ndmhwid, product
write_header "Данные из localhost:79/rci/show/defaults"
curl -kfsS "localhost:79/rci/show/defaults" | jq -r '.country, .ndmhwid, .product' >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 10. Запрос версии Xray
write_header "Версия Xray"
xray -version >> "$diagnostic" 
echo "Разрешено файловых дескрипторов:" >> "$diagnostic"
grep 'Max open files' "/proc/$(pidof xray)/limits" | awk '{print $4}' >> "$diagnostic" 
echo "Использовано файловых дескрипторов:" >> "$diagnostic"
ls -l /proc/$(pidof xray)/fd | wc -l >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

# 11. Запрос версии XKeen
write_header "Версия XKeen"
xkeen -v >> "$diagnostic" 
echo "" >> "$diagnostic"
echo "" >> "$diagnostic"

else
    echo "Запустите XKeen командой «xkeen -start»."
fi

echo ""
echo "  Диагностика закончилась"
echo "  Если требуется, можете включить XKeen"
echo "  Отправьте файл по пути «$diagnostic» в телеграм-чат XKeen, подробно описав возникшую проблему"
}