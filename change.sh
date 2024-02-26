#!/bin/bash

# Функция для выбора версии Xray-core
select_xray_version() {
    local latest_releases=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases?per_page=4")
    local versions=($(echo "$latest_releases" | grep -oP '"tag_name": "\K(.*?)(?=")'))
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
}

# Функция для поиска пути до папки Marzban-node и файла docker-compose.yml
find_marzban_node_dir() {
    local marzban_node_dir=""
    marzban_node_dir=$(find / -type d -name "Marzban-node" -exec test -f "{}/docker-compose.yml" \; -print -quit)
    echo "$marzban_node_dir"
}

# Функция для изменения ядра Marzban в папке Marzban-node
change_marzban_node_core() {
    local marzban_node_dir="$1"
    local xray_executable_path='XRAY_EXECUTABLE_PATH="/var/lib/marzban/xray-core/xray"'
    if ! grep -q "XRAY_EXECUTABLE_PATH: \"/var/lib/marzban/xray-core/xray\"" "$marzban_node_dir/docker-compose.yml"; then
        sed -i '/environment:/!b;n;/XRAY_EXECUTABLE_PATH/!a\      XRAY_EXECUTABLE_PATH: "/var/lib/marzban/xray-core/xray"' "$marzban_node_dir/docker-compose.yml"
    fi
    echo "Перезапуск Marzban-node..."
    cd "$marzban_node_dir" || exit
    docker compose up -d --force-recreate
}

# Функция для изменения ядра Marzban в папке marzban_folder
change_marzban_core() {
    local marzban_env_file="$1/.env"
    local xray_executable_path='XRAY_EXECUTABLE_PATH="/var/lib/marzban/xray-core/xray"'
    if ! grep -q "^${xray_executable_path}" "$marzban_env_file"; then
        echo "${xray_executable_path}" >> "${marzban_env_file}"
    fi
    echo "Перезапуск Marzban..."
    marzban restart -n
}

# Функция для установки Xray-core
install_xray_core() {
    local selected_version="$1"
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
    local xray_download_url="https://github.com/XTLS/Xray-core/releases/download/${selected_version}/${xray_filename}"
    echo "Скачивание Xray-core версии ${selected_version}..."
    wget "${xray_download_url}"
    # Извлекаем файл из архива и удаляем архив
    echo "Извлечение Xray-core..."
    unzip "${xray_filename}"
    rm "${xray_filename}"
}

# Выбор версии Xray-core
selected_version=$(select_xray_version)

# Если пользователь отказался от установки, выходим
if [ -z "$selected_version" ]; then
    exit 1
fi

# Путь до папки Marzban-node и файла docker-compose.yml по умолчанию
marzban_folder="/opt/marzban"

# Поиск пути до папки marzban_folder
if [ -d "$marzban_folder" ]; then
    marzban_node_dir="$marzban_folder"
else
    marzban_node_dir=$(find_marzban_node_dir)
fi

# Если найдены обе папки, меняем ядро в обоих местах
if [ -n "$marzban_folder" ] && [ -n "$marzban_node_dir" ]; then
    change_marzban_node_core "$marzban_node_dir"
    change_marzban_core "$marzban_folder"
# Если найдена только папка marzban_folder, меняем ядро в ней
elif [ -n "$marzban_folder" ]; then
    change_marzban_core "$marzban_folder"
# Если найдена только папка Marzban-node, меняем ядро в ней
elif [ -n "$marzban_node_dir" ]; then
    change_marzban_node_core "$marzban_node_dir"
fi

# Установка Xray-core выбранной версии
install_xray_core "$selected_version"

echo "Установка завершена."
