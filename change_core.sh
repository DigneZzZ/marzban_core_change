#!/bin/bash

# Отправляем запрос к GitHub API для получения информации о последних четырех релизах
latest_releases=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases?per_page=4")

# Извлекаем версии из JSON-ответа
versions=($(echo "$latest_releases" | grep -oP '"tag_name": "\K(.*?)(?=")'))

# Печатаем доступные версии
echo "Доступные версии Xray-core:"
for ((i=0; i<${#versions[@]}; i++)); do
    echo "$(($i + 1)): ${versions[i]}"
done

# Предлагаем пользователю выбрать версию
printf "Выберите версию для установки (1-${#versions[@]}), или нажмите Enter для выбора последней по умолчанию (${versions[0]}): "
read choice

# Проверяем, был ли сделан выбор пользователем
if [ -z "$choice" ]; then
    choice="1"  # Выбираем самую свежую версию по умолчанию
fi

# Преобразуем выбор пользователя в индекс массива
choice=$((choice - 1))

# Проверяем, что выбор пользователя в пределах доступных версий
if [ "$choice" -lt 0 ] || [ "$choice" -ge "${#versions[@]}" ]; then
    echo "Неверный выбор. Выбрана последняя версия по умолчанию (${versions[0]})."
    choice=$((${#versions[@]} - 1))  # Выбираем последнюю версию по умолчанию
fi

# Выбираем версию Xray-core для установки
selected_version=${versions[choice]}
echo "Выбрана версия $selected_version для установки."

# Проверяем, установлены ли необходимые пакеты
if ! dpkg -s wget unzip >/dev/null 2>&1; then
  echo "Установка необходимых пакетов..."
  apt install -y wget unzip
fi

# Создаем папку /var/lib/marzban/xray-core
mkdir -p /var/lib/marzban/xray-core
# Переходим в папку /var/lib/marzban/xray-core
cd /var/lib/marzban/xray-core

# Скачиваем Xray-core выбранной версии
xray_filename="Xray-linux-64.zip"
xray_download_url="https://github.com/XTLS/Xray-core/releases/download/${selected_version}/${xray_filename}"

echo "Скачивание Xray-core версии ${selected_version}..."
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
