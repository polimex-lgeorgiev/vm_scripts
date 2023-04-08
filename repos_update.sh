#!/bin/bash

# Запомняне на текущата директория
start_dir=$(pwd)

# Директория, където ще търсим клоновете
root_dir=""

# Проверка дали е подаден опционален параметър за root_dir
if [ $# -eq 1 ]; then
    if [ $1 == "-h" ]; then
        echo "Usage: $0 [root_dir]"
        echo "  root_dir - the directory where the script will search for git repos,"
        echo "             ignoring folders named 'odoo', 'polimex' and containing 'venv' in their names."
        echo "            If not provided, the script will use the default value: /opt/odoo15/custom_addons"
        exit 0
    else
        root_dir=$1
    fi
fi

# Check if root_dir exists or there are more than one folder in /opt
if [ ! -d "$root_dir" ]; then
    opt_dirs=(/opt/*/)
    if [ ${#opt_dirs[@]} -eq 1 ]; then
        root_dir=${opt_dirs[0]}custom-addons
    else
        echo "Please choose a directory from the list below:"
        select choice in /opt/*/; do
            if [ -n "$choice" ]; then
                root_dir=$choice"custom-addons"
                break
            else
                echo "Invalid selection. Please choose a valid directory."
            fi
        done
    fi
fi

# Extract the user name from the root directory path
user_name=$(echo "$root_dir" | sed 's:.*/\([^/]*\)/.*:\1:')

# Обхождане на всички директории и поддиректории в root_dir, игнорирайки директории с име 'odoo', 'polimex' или съдържащи 'venv' в името си
sudo -u "$user_name" bash -c "find \"$root_dir\" -type d -name \".git\" \
  -not -path \"*/odoo/*\" \
  -not -path \"*/polimex/*\" \
  -not -path \"*/venv/*\" | while read dir; do
    # Опресняване на репозитория с git pull
    echo \"Updating \$(dirname \"\$dir\")\"
    cd \"\$(dirname \"\$dir\")\" && git pull
done"

# Връщане в текущата директория
cd $start_dir
