#!/bin/bash
menu(){
	echo    " ---------------------------------"
	echo    "     DATOS DE RED DEL EQUIPO      "
	echo    " ---------------------------------"
	echo	" Direcciones IP: "
	ip -o -4 addr show | cut -d " " -f2,7 | sed "s/^/ /"
	echo    " ---------------------------------"
	echo	" Estado del servicio SSH: "
	systemctl is-active ssh | sed "s/^/ /"
	echo	" ---------------------------------"
	echo	"            SERVICIO SSH          "
	echo    " ---------------------------------"
	echo	" --1 Instalación servicio "
	echo	" --2 Desinstalación servicio "
	echo	" --3 Arranque servicio "
	echo	" --4 Detención servicio "
	echo	" --5 Consulta de logs "
	echo	" --6 Configuración dirección IP "
	echo    " --7 Configuración SSH "
	echo    " --8 Salir "
	echo    " ---------------------------------"
}
configurar_ip(){
	read -p "¿Quieres cambiar la configuración de la interfaz de red? (Y/N): " respuesta

	if [[ "$respuesta" == "Y" || "$respuesta" == "y" ]]; then
		echo "Interfaces de red disponibles:"
		ip -o link show | tr " " ":" | cut -d: -f3
		read -p "Introduce el nombre de la interfaz: " interfaz
		if ! ip link show $interfaz &> /dev/null; then
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
}
menu
while true; do
	echo "¡Bienvenido!"
	read -p "¿Qué acción deseas realizar? (--[1-8]): " orden
	case $orden in
		--1)
			echo " ---------------------------------"
			echo " Instalación servicio SSH "
			echo " ---------------------------------"
			echo " --1 Instalar con comandos "
			echo " --2 Instalar con Ansible "
			echo " --3 Instalar con Docker "
			echo " --4 Salir "
			echo " ---------------------------------"
			while true; do
				read -p "Introduce la forma a instalar (--[1-4]): " forma
				case $forma in
					--1)
						echo "Instalando SSH con comandos..."
						sudo apt update && sudo apt install openssh-server -y
						echo "SSH se ha instalado correctamente"
						exit 0
						;;
					--2)
						echo "Instalando SSH con Ansible..."
						exit 0
						;;
					--3)
						echo "Instalando SSH con Docker..."
						exit 0
						;;
					--4)
						echo "Saliendo..."
                        			exit 0
						;;
					*)
						echo "Opción inválida, elija --n"
						;;
				esac
				read -p "Presione Enter para continuar..."
			done
			;;
		--2)
  			;;
		--3)
                	;;
   		--4)
                	;;
   		--5)
                	;;
		--6)
			configurar_ip
			break
			;;
		--7)
			;;
        	--8)
			echo  "Saliendo..."
			break
                	;;
        	*)
			echo "Opción inválida, elija --n"
	        	;;
	esac
	read -p "Presione Enter para continuar..."
done