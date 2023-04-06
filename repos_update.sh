#!/bin/bash

# Запомняне на текущата директория
start_dir=$(pwd)

# Директория, където ще търсим клоновете
root_dir="/opt/odoo15/custom_addons"

# Проверка дали е подаден опционален параметър за root_dir
if [ $# -eq 1 ]; then
    if [ $1 == "-h" ]; then
        echo "Usage: $0 [root_dir]"
        echo "  root_dir - the directory where the script will search for git repos"
        echo "            if not provided, the script will use the default value: $root_dir"
        exit 0
    elif [ $1 == "." ]; then
        root_dir=$start_dir
    else
        root_dir=$1
    fi
fi

# Обхождане на всички директории и поддиректории в root_dir
find "$root_dir" -type d -name ".git" | while read dir
do
    # Опресняване на репозитория с git pull
    echo "Updating $(dirname "$dir")"
    cd "$(dirname "$dir")"
    git pull
done

# Връщане в текущата директория
cd $start_dir