#!/bin/bash

# Проверка дали потребителят е root
if [ "$EUID" -ne 0 ]; then
  echo "Моля, стартирайте този скрипт с права на root."
  exit
fi

# Показване на списък с мрежови интерфейси
echo "Налични мрежови интерфейси:"
interfaces=($(ip -o link show | awk -F': ' '{print $2}'))
for i in "${!interfaces[@]}"; do
  echo "$i) ${interfaces[$i]}"
done

# Потребителят избира мрежов интерфейс чрез число
read -p "Изберете номер на мрежовия интерфейс от списъка: " interface_number

# Проверка дали избраният номер е валиден
if ! [[ "$interface_number" =~ ^[0-9]+$ ]] || [ "$interface_number" -ge "${#interfaces[@]}" ]; then
  echo "Невалиден избор. Моля, изберете валидно число."
  exit
fi

# Избраният интерфейс
interface="${interfaces[$interface_number]}"

# Получаване на текущия MAC адрес
current_mac=$(ip link show "$interface" | grep ether | awk '{print $2}')
echo "Текущият MAC адрес на $interface е: $current_mac"

# Презареждане на интерфейса (може да е полезно за всякакви настройки)
ip link set dev "$interface" down
ip link set dev "$interface" up
echo "MAC адресът $current_mac е успешно настроен за $interface."

# Изтриване на стари настройки
echo "Изчистване на стари мрежови настройки..."
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f /var/lib/NetworkManager/*.state
echo "Старите мрежови настройки бяха изтрити."

# Рестартиране на systemd-networkd
echo "Рестартиране на systemd-networkd..."
systemctl restart systemd-networkd
echo "systemd-networkd е рестартиран."

# Потвърждение на текущия MAC адрес след промяната
updated_mac=$(ip link show "$interface" | grep ether | awk '{print $2}')
echo "Новият MAC адрес на $interface е: $updated_mac"

# Сравнение на стария и новия MAC адрес
if [ "$current_mac" != "$updated_mac" ]; then
  echo "MAC адресът беше успешно сменен."
else
  echo "MAC адресът не беше променен."
fi

echo "Процесът е завършен успешно."
