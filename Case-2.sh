#!/bin/bash
ip_actual=$(hostname -I | tr " " "\n" | grep -E "^192\.168\." | head -n1)

if [ -z "$ip_actual" ]; then
	echo "No se encontró ninguna IP en la red 192.168.x.x"
fi

echo "Tu IP actual en la red interna es: $ip_actual"

read -p "¿Quieres cambiar la IP? (Y/N): " respuesta

if [[ "$respuesta" == "Y" || "$respuesta" == "y" ]]; then
	read -p "Introduce la nueva IP (formato 192.168.x.x): " ip_nueva
	read -p "Introduce la máscara de red (ej. 255.255.255.0): " mascara
	read -p "Introduce la puerta de enlace (ej. 192.168.1.1): " puerta_enlace

	interfaz=$(ip a | grep -B2 "$ip_actual" | head -n1 | tr " " ":" | cut -d: -f3)

	if [ -z "$interfaz" ]; then
		echo "Error detectando la interfaz."
	fi

	echo "Configurando nueva IP en la interfaz $interfaz."

	sudo ip addr flush dev $interfaz
	sudo ip addr add $ip_nueva/$mascara dev $interfaz
	sudo ip route add default via $puerta_enlace

	echo "Nueva IP configurada: $ip_nueva"
else
	echo "No se han realizado cambios"
fi
