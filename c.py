#!/usr/bin/env python3

import os
import subprocess
import requests
import sys

def select_xray_version():
    latest_releases = requests.get("https://api.github.com/repos/XTLS/Xray-core/releases?per_page=4").json()
    versions = [release["tag_name"] for release in latest_releases]
    print("Доступные версии Xray-core:")
    for i, version in enumerate(versions):
        print(f"{i+1}: {version}")
    choice = input(f"Выберите версию для установки (1-{len(versions)}), или нажмите Enter для отказа: ")
    if not choice:
        print("Установка ядра отменена.")
        sys.exit(1)
    choice = int(choice) - 1
    if choice < 0 or choice >= len(versions):
        print("Неверный выбор. Установка ядра отменена.")
        sys.exit(1)
    selected_version = versions[choice]
    print(f"Выбрана версия {selected_version} для установки.")
    return selected_version

def find_marzban_node_dir():
    marzban_node_dir = None
    for root, dirs, files in os.walk("/"):
        if "docker-compose.yml" in files and "Marzban-node" in root:
            marzban_node_dir = root
            break
    return marzban_node_dir

def change_marzban_node_core(marzban_node_dir):
    xray_executable_path = 'XRAY_EXECUTABLE_PATH="/var/lib/marzban/xray-core/xray"'
    with open(os.path.join(marzban_node_dir, "docker-compose.yml"), "r") as f:
        content = f.read()
    if "XRAY_EXECUTABLE_PATH" not in content:
        content = content.replace("environment:", "environment:\n      " + xray_executable_path)
        with open(os.path.join(marzban_node_dir, "docker-compose.yml"), "w") as f:
            f.write(content)
    print("Перезапуск Marzban-node...")
    subprocess.run(["cd", marzban_node_dir], shell=True)
    subprocess.run(["docker", "compose", "up", "-d", "--force-recreate"], check=True)

def change_marzban_core(marzban_folder):
    xray_executable_path = 'XRAY_EXECUTABLE_PATH="/var/lib/marzban/xray-core/xray"'
    marzban_env_file = os.path.join(marzban_folder, ".env")
    with open(marzban_env_file, "a") as f:
        f.write(f"{xray_executable_path}\n")
    print("Перезапуск Marzban...")
    subprocess.run(["marzban", "restart", "-n"], check=True)

def install_xray_core(selected_version):
    if not os.path.exists("/var/lib/marzban/xray-core"):
        os.makedirs("/var/lib/marzban/xray-core")
    os.chdir("/var/lib/marzban/xray-core")
    xray_filename = "Xray-linux-64.zip"
    xray_download_url = f"https://github.com/XTLS/Xray-core/releases/download/v{selected_version}/{xray_filename}"
    print(f"Скачивание Xray-core версии {selected_version}...")
    subprocess.run(["wget", xray_download_url], check=True)
    print("Извлечение Xray-core...")
    subprocess.run(["unzip", xray_filename], check=True)
    os.remove(xray_filename)

selected_version = select_xray_version()

marzban_folder = "/opt/marzban"
marzban_node_dir = find_marzban_node_dir()

if marzban_folder and marzban_node_dir:
    change_marzban_node_core(marzban_node_dir)
    change_marzban_core(marzban_folder)
elif marzban_folder:
    change_marzban_core(marzban_folder)
elif marzban_node_dir:
    change_marzban_node_core(marzban_node_dir)

install_xray_core(selected_version)

print("Установка завершена.")
