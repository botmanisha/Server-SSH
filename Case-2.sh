#!/bin/bash
configurar_ip() {
    while true; do
        echo "Interfaces disponibles: "
	mostrar_interfaces() {
   		 ip -o link show | cut -d' ' -f2 | tr -d ':'
	}
        mostrar_interfaces
      
	read -p "Seleccione la interfaz correcta (enp0s3|enp0s8): " interfaz

        conexion=$(comprobar_conexion "$interfaz")

        if [[ "$conexion" == "NAT" ]]; then
            echo "La interfaz $interfaz está configurada con NAT."
        elif [[ "$conexion" == "Adaptador puente" ]]; then
            echo "La interfaz $interfaz está configurada con Adaptador puente."
        else
            echo "Interfaz no reconocida. Por favor, intente nuevamente."
            continue
        fi

        # Preguntar si la interfaz seleccionada es la correcta
        read -p "¿Es esta la interfaz correcta? (s/n): " respuesta
        if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
            break
        fi
    done
