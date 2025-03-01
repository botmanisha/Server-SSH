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
menu
instalacion_docker(){
       sudo apt install apt-transport-https ca-certificates curl software-properties-common -y #&> /dev/null
       curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - #&> /dev/null
       sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" #&> /dev/null
       sudo apt update #&> /dev/null
       apt-cache policy docker-ce #&> /dev/null
       sudo apt install docker-ce -y #&> /dev/null
       sudo usermod -aG docker $USER
       su - $USER
       echo "Docker ha sido instalado correctamente."
}
comprobar_instalacion_docker() {
       docker images &> /dev/null
       if [ $? -eq 0 ]; then
             echo "Docker está instalado y funcionando correctamente."
       else
	     echo "Instalando SSH con Docker..."
             instalacion_docker
             sudo systemctl start docker
	     sudo systemctl enable docker
	     version=$(docker --version)
	     echo "Docker instalado correctamente: $version"
       fi
}

instalacion_ssh_docker(){
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

instalar_ssh_ansible() {
read -p "Ingrese la IP del servidor donde instalar SSH: " ip_servidor
read -p "Ingrese el usuario SSH del servidor: " usuario_ssh
if ! systemctl is-active --quiet ssh; then
     echo "El servicio SSH no está instalado o no está activo. Instalando SSH..."
     sudo apt update && sudo apt install openssh-server -y
     echo "SSH ha sido instalado correctamente."
else
     echo "El servicio SSH ya está instalado y activo."
fi

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
     sudo apt update && sudo apt install ansible -y
     echo "Ansible ha sido instalado correctamente."
fi
     echo "[ssh_servers]" > hosts.ini
     echo "$ip_servidor ansible_user=$usuario_ssh ansible_ssh_private_key_file=~/.ssh/id_rsa" >> hosts.ini
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
        echo "Instalando SSH con comandos..."
        sudo apt update && sudo apt install openssh-server -y

        echo "SSH se ha instalado correctamente"
        exit 0
        ;;

    --2)
        echo "Instalando SSH con Ansible..."
        instalar_ssh_ansible
        exit 0
        ;;

    --3)
	comprobar_instalacion_docker
	echo "Procediendo a la instalación del servicio SSH mediante docker..."
	instalacion_ssh_docker
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
        echo "Desinstalando SSH con comandos..."
        sudo systemctl stop ssh
        sudo apt remove --purge openssh-server -y
        echo "SSH se ha desinstalado correctamente"
        exit 0
        ;;

    --2)
        echo "Desinstalando SSH con Ansible..."
    read -p "Ingrese la IP del servidor donde desinstalar SSH: " ip_servidor
    read -p "Ingrese el usuario SSH del servidor: " usuario_ssh

    echo "[ssh_servers]" > hosts.ini
    echo "$ip_servidor ansible_user=$usuario_ssh ansible_ssh_private_key_file=~/.ssh/id_rsa" > hosts.ini

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
        exit 0
        ;;

    --3)
        echo "Desinstalando SSH con Docker..."
        docker stop docker_ssh
        docker rm docker_ssh
        echo "ELiminando la imagen SSH_IMAGE..."
	docker rmi ssh_image
	echo "Contenedor Docker SSH detenido y eliminado"
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

logs(){
        echo " ---------------------------------"
        echo " Consulta de logs "
        echo " ---------------------------------"
        echo " --1 Logs por fecha "
        echo " --2 Logs por tipo "
        echo " --3 Salir "
        echo " ---------------------------------"
        while true; do
        read -p "Introduce la forma a desinstalar (--[1-3]): " consulta
        case $consulta in
            --1)
                echo "Logs por fecha: "
                echo " ---------------------------------"
                read -p "Introduce la fecha (YYYY-MM-DD): " fecha
                journalctl -u ssh --since "$fecha 00:00:00" --until "$fecha 23:59:59"
                exit 0
                ;;
            --2)
                echo "Logs por tipo: "
                echo " ---------------------------------"
                read -p "Introduce el tipo de log (error, warning, info): " tipo
                journalctl -u ssh | grep -i "$tipo"
                exit 0
		;;
            --3)
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


while true; do
	echo "¡Bienvenido!"
	read -p "¿Qué acción deseas realizar? (--[1-8]): " orden
	case $orden in
		--1)
		    instalacion
		    break
		    ;;

	        --2)
		    desinstalacion
		    echo 'Desintalación completada con exito.'
	            break
                    ;;

		--3)
		   echo "Iniciando el servicio SSH..."
		   sudo systemctl start ssh
		   sudo systemctl enable ssh
	           echo "Servicio SSH iniciado correctamente"
		   break
               	   ;;

   		--4)
		   echo "Deteniendo el servicio SSH..."
                   sudo systemctl stop ssh
                   sudo systemctl disable ssh
                   echo "Servicio SSH detenido correctamente"
           	   break
               	   ;;

   		--5)
		   logs
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

