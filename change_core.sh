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
xray_version="1.8.6"
xray_filename="Xray-linux-64.zip"
xray_download_url="https://github.com/XTLS/Xray-core/releases/download/v${xray_version}/${xray_filename}"

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
# Комментируем все вхождения переменной XRAY_EXECUTABLE_PATH
perl -i -pe 's/^XRAY_EXECUTABLE_PATH=.*$//' "${marzban_env_file}"

# Добавляем новое значение переменной XRAY_EXECUTABLE_PATH после последней закомментированной строки (если есть)
# perl -i -pe 's/^# XRAY_EXECUTABLE_PATH=/\0\n'${xray_executable_path}'/' "${marzban_env_file}"
echo ${xray_executable_path} >> "${marzban_env_file}"

# Перезапускаем Marzban
echo "Перезапуск Marzban..."
marzban restart -n

echo "Установка завершена."
