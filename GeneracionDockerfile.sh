#!/bin/bash

# Script de gestión del contenedor VS Code Server
# Autor: Configuración Docker VS Code Server
# Uso: ./manage-container.sh [comando]

CONTAINER_NAME="code-server"
IMAGE="lscr.io/linuxserver/code-server:latest"
WORKSPACE_PATH="/var/www/html/universe-stable"
PASSWORD="dev123"
PORT="8443"

# Función para mostrar el estado del contenedor
show_status() {
    echo "📊 Estado actual del contenedor:"
    if docker ps | grep -q $CONTAINER_NAME; then
        echo "✅ Contenedor está ejecutándose"
        docker ps | grep $CONTAINER_NAME
        echo ""
        echo "🌐 Acceso web: http://localhost:$PORT (vía túnel SSH)"
        echo "🔑 Password: $PASSWORD"
    elif docker ps -a | grep -q $CONTAINER_NAME; then
        echo "⏹️ Contenedor existe pero está detenido"
        docker ps -a | grep $CONTAINER_NAME
    else
        echo "❌ Contenedor no existe"
    fi
}

# Función para crear/recrear el contenedor
create_container() {
    echo "🔧 Creando contenedor $CONTAINER_NAME..."
    
    # Detener y eliminar contenedor existente si existe
    if docker ps -a | grep -q $CONTAINER_NAME; then
        echo "🛑 Deteniendo contenedor existente..."
        sudo docker stop $CONTAINER_NAME 2>/dev/null
        echo "🗑️ Eliminando contenedor existente..."
        sudo docker rm $CONTAINER_NAME 2>/dev/null
    fi
    
    # Crear nuevo contenedor
    echo "🚀 Creando nuevo contenedor..."
    sudo docker run -d \
      --name $CONTAINER_NAME \
      -e PUID=$(id -u) \
      -e PGID=$(id -g) \
      -e PASSWORD="$PASSWORD" \
      -p $PORT:8443 \
      -v "$WORKSPACE_PATH:/config/workspace" \
      --restart unless-stopped \
      $IMAGE
    
    if [ $? -eq 0 ]; then
        echo "✅ Contenedor creado exitosamente"
        sleep 3
        show_status
    else
        echo "❌ Error al crear el contenedor"
        exit 1
    fi
}

# Función para verificar requisitos
check_requirements() {
    echo "🔍 Verificando requisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker no está instalado"
        echo "📋 Para instalarlo ejecuta:"
        echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "   sudo sh get-docker.sh"
        echo "   sudo usermod -aG docker \$USER"
        exit 1
    fi
    
    # Verificar que el usuario esté en el grupo docker
    if ! groups $USER | grep -q docker; then
        echo "⚠️ Usuario no está en el grupo docker"
        echo "📋 Ejecuta: sudo usermod -aG docker \$USER"
        echo "   Luego reinicia la sesión"
    fi
    
    # Verificar directorio de workspace
    if [ ! -d "$WORKSPACE_PATH" ]; then
        echo "⚠️ Directorio de workspace no existe: $WORKSPACE_PATH"
        echo "🔧 Creando directorio..."
        sudo mkdir -p "$WORKSPACE_PATH"
        sudo chown -R $(id -u):$(id -g) "$WORKSPACE_PATH"
    fi
    
    # Verificar firewall
    echo "🔥 Verificando firewall..."
    if sudo firewall-cmd --list-ports | grep -q "$PORT"; then
        echo "✅ Puerto $PORT está abierto en firewall"
    else
        echo "⚠️ Puerto $PORT no está abierto en firewall"
        echo "🔧 Abriendo puerto..."
        sudo firewall-cmd --add-port=$PORT/tcp --permanent
        sudo firewall-cmd --reload
        echo "✅ Puerto $PORT abierto"
    fi
    
    echo "✅ Verificación completada"
}

# Script principal
case "$1" in
    start)
        echo "🚀 Iniciando contenedor..."
        sudo docker start $CONTAINER_NAME
        if [ $? -eq 0 ]; then
            echo "✅ Contenedor iniciado"
            sleep 2
            show_status
        else
            echo "❌ Error al iniciar contenedor"
            echo "💡 Intenta: $0 recreate"
        fi
        ;;
    stop)
        echo "⏹️ Deteniendo contenedor..."
        sudo docker stop $CONTAINER_NAME
        if [ $? -eq 0 ]; then
            echo "✅ Contenedor detenido"
        else
            echo "❌ Error al detener contenedor"
        fi
        ;;
    restart)
        echo "🔄 Reiniciando contenedor..."
        sudo docker restart $CONTAINER_NAME
        if [ $? -eq 0 ]; then
            echo "✅ Contenedor reiniciado"
            sleep 2
            show_status
        else
            echo "❌ Error al reiniciar contenedor"
        fi
        ;;
    status)
        show_status
        ;;
    logs)
        echo "📋 Logs del contenedor (Ctrl+C para salir):"
        docker logs -f $CONTAINER_NAME
        ;;
    shell)
        echo "🐚 Accediendo al shell del contenedor..."
        if docker ps | grep -q $CONTAINER_NAME; then
            docker exec -it $CONTAINER_NAME /bin/bash
        else
            echo "❌ Contenedor no está ejecutándose"
            echo "💡 Inicia el contenedor con: $0 start"
        fi
        ;;
    remove)
        echo "🗑️ Eliminando contenedor..."
        read -p "¿Estás seguro? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo docker stop $CONTAINER_NAME 2>/dev/null
            sudo docker rm $CONTAINER_NAME
            echo "✅ Contenedor eliminado"
        else
            echo "❌ Operación cancelada"
        fi
        ;;
    recreate)
        echo "🔧 Recreando contenedor desde cero..."
        check_requirements
        create_container
        ;;
    setup)
        echo "⚙️ Configuración inicial completa..."
        check_requirements
        create_container
        echo ""
        echo "🎉 ¡Configuración completada!"
        echo "📋 Próximos pasos:"
        echo "   1. Desde tu máquina local ejecuta: ./connect.sh"
        echo "   2. Abre navegador en: http://localhost:$PORT"
        echo "   3. Usa password: $PASSWORD"
        ;;
    check)
        check_requirements
        ;;
    info)
        echo "ℹ️ Información del contenedor:"
        echo "   Nombre: $CONTAINER_NAME"
        echo "   Imagen: $IMAGE"
        echo "   Puerto: $PORT"
        echo "   Password: $PASSWORD"
        echo "   Workspace: $WORKSPACE_PATH"
        echo "   URL local (vía túnel): http://localhost:$PORT"
        echo ""
        show_status
        ;;
    *)
        echo "🐳 Gestión del Contenedor VS Code Server"
        echo "======================================"
        echo ""
        echo "Uso: $0 {comando}"
        echo ""
        echo "📋 Comandos disponibles:"
        echo "   setup     - Configuración inicial completa (usar en primera instalación)"
        echo "   start     - Iniciar contenedor"
        echo "   stop      - Detener contenedor"
        echo "   restart   - Reiniciar contenedor"
        echo "   status    - Ver estado del contenedor"
        echo "   logs      - Ver logs del contenedor en tiempo real"
        echo "   shell     - Acceder al shell del contenedor"
        echo "   remove    - Eliminar contenedor"
        echo "   recreate  - Recrear contenedor desde cero"
        echo "   check     - Verificar requisitos del sistema"
        echo "   info      - Mostrar información del contenedor"
        echo ""
        echo "🚀 Para primera instalación: $0 setup"
        echo "📊 Para ver estado actual: $0 status"
        exit 1
        ;;
esac