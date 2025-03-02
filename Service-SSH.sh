#!/bin/bash
ayuda(){
	echo "----------------------------------"
	echo "Uso: $0 [OPCIÓN]"
	echo "----------------------------------"
	echo "Opciones:"
	echo "-h, --help              -Muestra esta ayuda"
	echo "-instdoc                -Instala Docker y configura SSH en un contenedor"
	echo "-instcom                -Instala SSH usando comandos de sistema"
	echo "-instans                -Instala SSH usando Ansible"
	echo "-desdoc                 -Desinstala SSH en un contenedor Docker"
	echo "-descom                 -Desinstala SSH usando comandos de sistema"
	echo "-desans                 -Desinstala SSH usando Ansible"
	echo "-start                  -Inicia el servicio SSH"
	echo "-stop                   -Detiene el servicio SSH"
        echo "-status                 -Muestra el estado del servicio SSH"
	echo "-confip                 -Configura la dirección IP de la interfaz de red"
	echo "-confssh                -Edita la configuración de SSH"
	echo "-logs                   -Muestra los logs de SSH"
	echo "----------------------------------"
	echo "Sin argumentos, se muestra el menú principal."
}
menu(){
	echo " ---------------------------------"
	echo "     DATOS DE RED DEL EQUIPO      "
	echo " ---------------------------------"
	echo " Direcciones IP: "
	ip -o -4 addr show | cut -d " " -f2,7 | sed "s/^/ /"
	echo " ---------------------------------"
	echo " Estado del servicio SSH: "
	systemctl is-active ssh | sed "s/^/ /"
	echo " ---------------------------------"
	echo "            SERVICIO SSH          "
	echo " ---------------------------------"
	echo " --1 Instalación servicio "
	echo " --2 Desinstalación servicio "
	echo " --3 Arranque servicio "
	echo " --4 Detención servicio "
	echo " --5 Consulta de logs "
	echo " --6 Configuración dirección IP "
	echo " --7 Configuración SSH "
        echo " --8 Estado del servicio SSH "
	echo " --9 Salir "
        echo " ---------------------------------"
        echo " --h  ACCESO AYUDA SERVICIO SSH   "
        echo " ---------------------------------"
        echo " ./Service-SSH.sh -h              "
        echo " ./Service-SSH.sh --help          "
	echo " ---------------------------------"
}
instalacion_comando(){
	echo "Instalando SSH con comandos..."
	sudo apt update && sudo apt install openssh-server -y
	echo "SSH se ha instalado correctamente"
}
instalacion_docker(){
	echo "Instalando SSH con Docker..."
	docker images &> /dev/null
	if [ $? -eq 0 ]; then
		echo "Docker está instalado y funcionando correctamente."
	else
		echo "Instalando SSH con Docker..."
		sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
		sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
		sudo apt update
		apt-cache policy docker-ce
		sudo apt install docker-ce -y
		sudo usermod -aG docker $USER
		su - $USER
		sudo systemctl start docker
		sudo systemctl enable docker
		version=$(docker --version)
		echo "Docker ha sido instalado correctamente: $version"
	fi
	echo "Procediendo a la instalación del servicio SSH mediante docker..."
	echo "Creando el Dockerfile..."
	cat <<EOF > Dockerfile
FROM ubuntu:latest
RUN apt-get update && \\
    apt-get install -y openssh-server && \\
    apt-get clean
RUN mkdir /var/run/sshd
EXPOSE 22
RUN useradd -m -s /bin/bash usuario && \\
    echo 'usuario:contraseña' | chpasswd && \\
    adduser usuario sudo
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \\
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \\
    echo "AllowUsers usuario" >> /etc/ssh/sshd_config
CMD ["/usr/sbin/sshd", "-D"]
EOF
	echo "Construyendo la imagen Docker: SSH_IMAGE"
	docker build -t ssh_image .
	echo "Ejecutando un contenedor con la imagen SSH_IMAGE..."
	docker run -d -p 2222:22 --name docker_ssh ssh_image
	echo "Contenedores en ejecución:"
	docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Ports}}\t{{.Status}}"
	echo "Iniciando el contenedor docker_ssh... "
	echo -e "Ingrese dentro del contenedor el siguiente comando para comprobar la instalación del servicio SSH\n <ps aux | grep ssh> :)"
	docker exec -it docker_ssh /bin/bash
}
instalacion_ansible(){
	echo "Instalando SSH con Ansible..."
	read -p "Ingrese la IP del servidor donde instalar SSH: " ip_servidor

	if ! sudo ufw status | grep -q "Status: active"; then
		echo "UFW no está activo. Activando UFW..."
		sudo ufw enable
	else
		echo "UFW ya está activo."
	fi

	if ! sudo ufw status | grep -q "22/tcp"; then
		echo "El puerto 22 no está permitido. Permitido ahora..."
		sudo ufw allow 22/tcp
	else
		echo "El puerto $PUERTO_SSH ya está permitido."
	fi
	sudo ufw reload
	echo "Reglas actuales de UFW:"
	sudo ufw status

	if ! ansible --version &> /dev/null; then
		echo "Ansible no está instalado. Instalándolo..."
		sudo apt install -y software-properties-common
		sudo apt-add-repository --yes --update ppa:ansible/ansible
		sudo apt update && sudo apt install ansible -y
		echo "Ansible ha sido instalado correctamente."
	fi
	ip_local=${ip_servidor:-localhost}
	echo "[ssh_servers]" > hosts.ini
	echo "$ip_local ansible_connection=local" >> hosts.ini
	cat > install_ssh.yml <<EOL
- name: Instalar y habilitar SSH
  hosts: ssh_servers
  become: yes
  tasks:
    - name: Instalar OpenSSH Server
      apt:
        name: openssh-server
        state: present
    - name: Habilitar y arrancar SSH
      systemd:
        name: ssh
        enabled: yes
        state: started
EOL
	ansible-playbook -i hosts.ini install_ssh.yml --ask-become-pass
	echo "Servicio SSH instalado correctamente con Ansible."
}
instalacion(){
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
				instalacion_comando
				exit 0
				;;

			--2)
				instalacion_ansible
				exit 0
				;;

			--3)
				instalacion_docker
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
}
desinstalacion_comando(){
	echo "Desinstalando SSH con comandos..."
	sudo systemctl stop ssh
	sudo apt remove --purge openssh-server -y
	echo "SSH se ha desinstalado correctamente"
}
desinstalacion_docker(){
	echo "Desinstalando SSH con Docker..."
	docker stop docker_ssh
	docker rm docker_ssh
	echo "ELiminando la imagen SSH_IMAGE..."
	docker rmi ssh_image
	echo "Contenedor Docker SSH detenido y eliminado"
}
desinstalacion_ansible(){
	echo "Desinstalando SSH con Ansible..."
	read -p "Ingrese la IP del servidor donde desinstalar SSH: " ip_servidor
	ip_local=${ip_servidor:-localhost}
	echo "[ssh_servers]" > hosts.ini
	echo "$ip_local ansible_connection=local" >> hosts.ini
	cat > uninstall_ssh.yml <<EOL
- name: Desinstalar SSH
  hosts: ssh_servers
  become: yes
  tasks:
    - name: Detener y deshabilitar SSH
      systemd:
        name: ssh
        state: stopped
        enabled: no
    - name: Desinstalar OpenSSH Server
      apt:
        name: openssh-server
        state: absent
EOL
	ansible-playbook -i hosts.ini uninstall_ssh.yml --ask-become-pass
	echo "Servicio SSH desinstalado correctamente con Ansible."
}
desinstalacion(){
	echo " ---------------------------------"
	echo " Desinstalación servicio SSH "
	echo " ---------------------------------"
	echo " --1 Desinstalar con comandos "
	echo " --2 Desinstalar con Ansible "
	echo " --3 Desinstalar con Docker "
	echo " --4 Salir "
	echo " ---------------------------------"
	while true; do
		read -p "Introduce la forma a desinstalar (--[1-4]): " formados
		case $formados in
			--1)
				desinstalacion_comando
				exit 0
				;;

			--2)
				desinstalacion_ansible
				exit 0
				;;

			--3)
				desinstalacion_docker
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
}
iniciar_servicio(){
	echo "Iniciando el servicio SSH..."
	sudo systemctl start ssh
	sudo systemctl enable ssh
	echo "Servicio SSH iniciado correctamente"
}
detener_servicio(){
	echo "Deteniendo el servicio SSH..."
	sudo systemctl stop ssh
	sudo systemctl disable ssh
	echo "Servicio SSH detenido correctamente"
}
configurar_ip(){
	read -p "¿Quieres cambiar la configuración de la interfaz de red? [Y/N]: " respuesta
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
		sudo ip addr flush dev $interfaz && sudo rm /etc/netplan/* &> /dev/null
		sudo ip addr add $ip_nueva/$mascara dev $interfaz
		sudo ip route add default via $puerta_enlace
		echo "Nueva IP configurada en $interfaz: $ip_nueva/$mascara"
		echo "Puerta de enlace: $puerta_enlace"
	else
		echo "No se han realizado cambios en la red"
	fi
}
editar_configuracion(){
	echo " ---------------------------------"
	echo " Editar Configuración SSH "
	echo " ---------------------------------"
	echo " --1 Cambiar el puerto SSH "
	echo " --2 Habilitar/Deshabilitar autenticación por contraseña "
	echo " --3 Abrir el archivo de configuracion "
	echo " --4 Salir "
	echo " ---------------------------------"
	while true; do
		read -p "Seleccione una opcion a configurar (--[1-4]): " confi
		case $confi in
			--1)
				read -p "Ingrese el nuevo puerto SSH: " puerto
				sudo sed -i "s/^#Port [0-9]\+/Port $puerto/" /etc/ssh/sshd_config
				echo "El puerto ha sido cambiado a $puerto"
				sudo systemctl restart ssh
				exit 0
				;;

			--2)
				read -p "¿Desea habilitar la autenticación por contraseña? (Y/N): " auten
				if [[ $auten == "Y" || $auten == "y" ]]; then
					sudo sed -i "s/^#\?PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
					echo "Autenticación por contraseña habilitada."
					sudo systemctl restart ssh
				else
					sudo sed -i "s/^#\?PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
					echo "Autenticación por contraseña deshabilitada."
					sudo systemctl restart ssh
				fi
				exit 0
				;;

			--3)
				sudo nano /etc/ssh/sshd_config
				sudo systemctl restart ssh
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
}
logs(){
	echo " ---------------------------------"
        echo " Consulta de logs "
        echo " ---------------------------------"
        echo " --1 Logs por fecha "
        echo " --2 Logs por tipo "
        echo " --3 Salir "
        echo " ---------------------------------"
        while true; do
        read -p "Elige el método para filtrar logs (--[1-3]): " consulta
        case $consulta in
            --1)
                echo "Logs por fecha: "
                echo " ---------------------------------"
                read -p "Introduce la fecha (YYYY-MM-DD): " fecha
                journalctl -u ssh --since "$fecha 00:00:00" --until "$fecha 23:59:59"
                ;;
            --2)
                echo "Logs por tipo: "
                echo "-------------------------------------------------------------"
                echo "Tipos de log"
                echo "emerg: Emergencias (el sistema no funciona)"
                echo "alert: Condiciones críticas que requieren atención inmediata"
                echo "err: Errores"
                echo "warning: Advertencias"
                echo "notice: Notificaciones"
                echo "info: Información"
                echo "debug: Depuración"
                echo "-------------------------------------------------------------"
                echo "Para salir introduzca: exit"
                echo "-------------------------------------------------------------"
                while true;do
                read -p "Introduce el tipo de log (error, warning, info): " tipo
                if [[ "$tipo" == "exit" ]]; then
                        break
                fi
                echo "Buscando logs con el tipo '$tipo': "
                case $tipo in
                        emerg)   priority=0 ;;
                        alert)   priority=1 ;;
                        crit)    priority=2 ;;
                        err)     priority=3 ;;
                        warning) priority=4 ;;
                        notice)  priority=5 ;;
                        info)    priority=6 ;;
                        debug)   priority=7 ;;
                        *)       echo "Tipo de log no válido"
                                 continue
                                 ;;
                esac
                journalctl -u ssh --priority="$tipo"
                read -p "Presione Enter para continuar..."
                done
                ;;
            --3)
                echo "Saliendo..."
                break
                ;;
            *)
                echo "Opción inválida, elija --n"
                ;;
        esac
        read -p "Presione Enter para continuar..."
    	done

}
if [ $# -eq 0 ]; then
	menu
	while true; do
		echo "¡Bienvenido!"
		read -p "¿Qué acción deseas realizar? (--[1-9]): " orden
		case $orden in
			--1)
				instalacion
				break
				;;

		        --2)
				desinstalacion
			        break
        		        ;;

			--3)
				iniciar_servicio
				break
       	        		;;

   			--4)
				detener_servicio
           			break
               			;;

	   		--5)
				logs
				break
		        	;;

			--6)
        			configurar_ip
                                break
                                ;;

 			--7)
                		editar_configuracion
				break
        	  		;;
                        --8)
                                systemctl status ssh
                                break
                                ;;

        		--9)
				echo  "Saliendo..."
				break
                		;;

			--h)
				ayuda
                                break
                                ;;

			*)
		   		echo "Opción inválida, elija --n"
	          		;;
		esac
		read -p "Presione Enter para continuar..."
	done
else
	case $1 in
		-h | --help)
			ayuda
			;;

		-instdoc)
			instalacion_docker
			;;

		-instcom)
			instalacion_comando
			;;

		-instans)
			instalacion_ansible
			;;

		-desdoc)
			desinstalacion_docker
			;;

		-descom)
			desinstalacion_comando
			;;

		-desans)
			desinstalacion_ansible
			;;

		-start)
			iniciar_servicio
			;;

		-stop)
			detener_servicio
			;;

		-confip)
			configurar_ip
			;;

		-confssh)
			editar_configuracion
			;;

		-logs)
			logs
			;;

		-status)
                        systemctl status ssh
                        ;;

		*)
			echo "Opción no válida. Usa -h o --help para ver las opciones disponibles."
			exit 1
			;;
	esac
fi
