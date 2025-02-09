#!/bin/bash

menu () {
	echo	" ---------------------------------"
	echo	"            SERVICIO SSH          "
	echo    " ---------------------------------" 
	echo	" --1 Actualizar Software "
	echo	" --2 Configuración dirección IP "
	echo	" --3 Instalación | Desinstalación "
	echo	" --4 Estado "
	echo    " --5 Configuración "
	echo    " --6 Salir "
	echo    " ---------------------------------"
}
while true; do
	menu
	read -p $"¡Bienvenido!\n¿Qué acción deseas realizar? (--[1-6]): " orden
case $orden in
	--1)
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
		echo  "Saliendo del servicio..."
		break
                ;;
        *)
		echo "Opción inválida, elija --n"
        	
	        ;;
esac
	read -p "Presione Enter para continuar..."
done
