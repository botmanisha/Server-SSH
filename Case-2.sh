#!/bin/bash
read -p "¿Quieres cambiar la configuración de la interfaz de red? (Y/N): " respuesta

if [[ "$respuesta" == "Y" || "$respuesta" == "y" ]]; then
	echo "Interfaces de red disponibles:"
	ip -o link show | tr " " ":" | cut -d: -f3
	read -p "Introduce el nombre de la interfaz: " interfaz
	if ! ip -o link show $interfaz | tr " " ":" | cut -d: -f3 &> /dev/null; then
		echo "Error: La interfaz $interfaz no exite."
		exit 1
	fi
	read -p "Introduce la nueva dirección IP (formato 192.168.x.x): " ip_nueva
	read -p "Introduce la máscara de red (ej. 255.255.255.0): " mascara
	read -p "Introduce la puerta de enlace (ej. 192.168.1.1): " puerta_enlace
	echo "Configurando nueva IP en la interfaz $interfaz..."
	sudo ip addr flush dev $interfaz
	sudo ip addr add $ip_nueva/$mascara dev $interfaz
	sudo ip route add default via $puerta_enlace

	echo "Nueva IP configurada en $interfaz: $ip_nueva/$mascara"
	echo "Puerta de enlace: $puerta_enlace"
else
	echo "No se han realizado cambios en la red"
fi
