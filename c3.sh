#!/bin/bash

# Выбор версии Xray-core
latest_releases=$(curl -s --max-time 10 "https://api.github.com/repos/XTLS/Xray-core/releases?per_page=4")
versions=($(echo "$latest_releases" | grep -oP '"tag_name": "\K(.*?)(?=")'))
echo "Доступные версии Xray-core:"
for ((i=0; i<${#versions[@]}; i++)); do
    echo "$(($i + 1)): ${versions[i]}"
done
printf "Выберите версию для установки (1-${#versions[@]}), или нажмите Enter для отказа: "
read choice
if [ -z "$choice" ]; then
    echo "Установка ядра отменена."
    exit 1
fi
choice=$((choice - 1))
if [ "$choice" -lt 0 ] || [ "$choice" -ge "${#versions[@]}" ]; then
    echo "Неверный выбор. Установка ядра отменена."
    exit 1
fi
selected_version=${versions[choice]}
echo "Выбрана версия $selected_version для установки."
echo "$selected_version"

# Поиск пути до папки Marzban-node и файла docker-compose.yml
marzban_node_dir=""
marzban_node_dir=$(find / -type d -name "Marzban-node" -exec test -f "{}/docker-compose.yml" \; -print -quit)
echo "$marzban_node_dir"

# Изменение ядра Marzban в папке Marzban-node
if [ -n "$marzban_node_dir" ]; then
    local xray_executable_path='XRAY_EXECUTABLE_PATH="/var/lib/marzban/xray-core/xray"'
    if ! grep -q "XRAY_EXECUTABLE_PATH: \"/var/lib/marzban/xray-core/xray\"" "$marzban_node_dir/docker-compose.yml"; then
        sed -i '/environment:/!b;n;/XRAY_EXECUTABLE_PATH/!a\      XRAY_EXECUTABLE_PATH: "/var/lib/marzban/xray-core/xray"' "$marzban_node_dir/docker-compose.yml"
    fi
    echo "Перезапуск Marzban-node..."
    cd "$marzban_node_dir" || exit
    docker compose up -d --force-recreate || { echo "Ошибка при запуске контейнера. Программа завершена."; exit 1; }
fi

# Изменение ядра Marzban в папке marzban_folder
marzban_folder="/opt/marzban"
if [ -d "$marzban_folder" ]; then
    local marzban_env_file="$marzban_folder/.env"
    local xray_executable_path='XRAY_EXECUTABLE_PATH="/var/lib/marzban/xray-core/xray"'
    if ! grep -q "^${xray_executable_path}" "$marzban_env_file"; then
        echo "${xray_executable_path}" >> "${marzban_env_file}"
    fi
    echo "Перезапуск Marzban..."
    marzban restart -n || { echo "Ошибка при перезапуске Marzban. Программа завершена."; exit 1; }
fi

# Установка Xray-core выбранной версии
# Проверяем, установлены ли необходимые пакеты
if ! dpkg -s wget unzip >/dev/null 2>&1; then
    echo "Установка необходимых пакетов..."
    apt install -y wget unzip
fi
# Создаем папку /var/lib/marzban/xray-core
mkdir -p /var/lib/marzban/xray-core
# Переходим в папку /var/lib/marzban/xray-core
cd /var/lib/marzban/xray-core || exit
# Скачиваем Xray-core выбранной версии
local xray_filename="Xray-linux-64.zip"
local xray_download_url="https://github.com/XTLS/Xray-core/releases/download/v${selected_version}/${xray_filename}"
echo "Скачивание Xray-core версии ${selected_version}..."
wget "${xray_download_url}"
# Извлекаем файл из архива и удаляем архив
echo "Извлечение Xray-core..."
unzip "${xray_filename}"
rm "${xray_filename}"

echo "Установка завершена."
