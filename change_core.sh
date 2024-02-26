#!/bin/bash

# Проверяем, установлены ли необходимые пакеты
if ! dpkg -s wget unzip >/dev/null 2>&1; then
  echo "Установка необходимых пакетов..."
  apt install -y wget unzip
fi

# Создаем папку /var/lib/marzban/xray-core
mkdir -p /var/lib/marzban/xray-core
# Переходим в папку /var/lib/marzban/xray-core
cd /var/lib/marzban/xray-core

# Скачиваем Xray-core
# Отправляем запрос к GitHub API для получения информации о последнем релизе
latest_release=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest")

# Извлекаем версию из JSON-ответа
xray_version=$(echo "$latest_release" | grep -oP '"tag_name": "\K(.*?)(?=")')

xray_filename="Xray-linux-64.zip"
xray_download_url="https://github.com/XTLS/Xray-core/releases/download/${xray_version}/${xray_filename}"

echo "Скачивание Xray-core..."
wget "${xray_download_url}"

# Извлекаем файл из архива и удаляем архив
echo "Извлечение Xray-core..."
unzip "${xray_filename}"
rm "${xray_filename}"

# Изменение ядра Marzban
marzban_folder="/opt/marzban"
marzban_env_file="${marzban_folder}/.env"
xray_executable_path='XRAY_EXECUTABLE_PATH="/var/lib/marzban/xray-core/xray"'

echo "Изменение ядра Marzban..."
# Проверяем, существует ли уже строка XRAY_EXECUTABLE_PATH в файле .env
if ! grep -q "^${xray_executable_path}" "$marzban_env_file"; then
  # Если строка отсутствует, добавляем ее
  echo "${xray_executable_path}" >> "${marzban_env_file}"
fi

# Перезапускаем Marzban
echo "Перезапуск Marzban..."
marzban restart -n

echo "Установка завершена."
