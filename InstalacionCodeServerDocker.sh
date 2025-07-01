#!/bin/bash

# Script de instalación rápida para VS Code Server Docker
# Autor: Configuración Docker VS Code Server
# Uso: ./quick-setup.sh

echo "🚀 INSTALACIÓN RÁPIDA VS CODE SERVER DOCKER"
echo "==========================================="
echo ""

# Variables de configuración
CONTAINER_NAME="code-server"
IMAGE="lscr.io/linuxserver/code-server:latest"
WORKSPACE_PATH="/var/www/html/universe-stable"
PASSWORD="dev123"
PORT="8443"
SERVER_IP="10.14.102.22"
SSH_PORT="50493"

# Función para mostrar error y salir
error_exit() {
    echo "❌ Error: $1"
    exit 1
}

# Función para verificar comando
check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

echo "🔍 Paso 1: Verificando requisitos del sistema..."

# Verificar que estamos en el servidor correcto
if ! ip addr show | grep -q "$SERVER_IP"; then
    echo "⚠️ Este script debe ejecutarse en el servidor $SERVER_IP"
    echo "📍 IP actual del servidor:"
    ip addr show | grep "inet " | grep -v "127.0.0.1"
    read -p "¿Continuar de todas formas? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verificar Docker
if ! check_command docker; then
    echo "📦 Docker no está instalado. Instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh || error_exit "No se pudo instalar Docker"
    sudo usermod -aG docker $USER
    echo "✅ Docker instalado correctamente"
    echo "⚠️ Necesitas reiniciar la sesión para usar Docker sin sudo"
    echo "   Ejecuta: logout && ssh -p $SSH_PORT $USER@$SERVER_IP"
    echo "   Luego vuelve a ejecutar este script"
    exit 0
else
    echo "✅ Docker ya está instalado"
fi

# Verificar grupo docker
if ! groups $USER | grep -q docker; then
    echo "🔧 Agregando usuario al grupo docker..."
    sudo usermod -aG docker $USER
    echo "⚠️ Necesitas reiniciar la sesión para aplicar cambios"
    echo "   Ejecuta: logout && ssh -p $SSH_PORT $USER@$SERVER_IP"
    echo "   Luego vuelve a ejecutar este script"
    exit 0
fi

echo "🔥 Paso 2: Configurando firewall..."

# Verificar y configurar firewall
if check_command firewall-cmd; then
    if ! sudo firewall-cmd --list-ports | grep -q "$PORT"; then
        echo "🔧 Abriendo puerto $PORT en firewall..."
        sudo firewall-cmd --add-port=$PORT/tcp --permanent
        sudo firewall-cmd --reload
        echo "✅ Puerto $PORT abierto en firewall"
    else
        echo "✅ Puerto $PORT ya está abierto"
    fi
else
    echo "⚠️ firewall-cmd no disponible, verificando iptables..."
    if check_command iptables; then
        # Verificar si el puerto está abierto en iptables
        if ! sudo iptables -L INPUT -n | grep -q "$PORT"; then
            echo "🔧 Abriendo puerto $PORT en iptables..."
            sudo iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
            echo "✅ Puerto $PORT abierto en iptables"
        fi
    fi
fi

echo "📁 Paso 3: Configurando directorio de trabajo..."

# Crear y configurar directorio de workspace
if [ ! -d "$WORKSPACE_PATH" ]; then
    echo "🔧 Creando directorio de workspace..."
    sudo mkdir -p "$WORKSPACE_PATH"
fi

# Dar permisos apropiados
sudo chown -R $(id -u):$(id -g) "$WORKSPACE_PATH"
echo "✅ Directorio de workspace configurado: $WORKSPACE_PATH"

echo "🐳 Paso 4: Configurando contenedor Docker..."

# Detener y eliminar contenedor existente si existe
if docker ps -a | grep -q $CONTAINER_NAME; then
    echo "🛑 Deteniendo contenedor existente..."
    docker stop $CONTAINER_NAME 2>/dev/null
    echo "🗑️ Eliminando contenedor existente..."
    docker rm $CONTAINER_NAME 2>/dev/null
fi

# Descargar imagen
echo "📥 Descargando imagen Docker..."
docker pull $IMAGE || error_exit "No se pudo descargar la imagen Docker"

# Crear contenedor
echo "🚀 Creando contenedor..."
docker run -d \
  --name $CONTAINER_NAME \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e PASSWORD="$PASSWORD" \
  -p $PORT:8443 \
  -v "$WORKSPACE_PATH:/config/workspace" \
  --restart unless-stopped \
  $IMAGE || error_exit "No se pudo crear el contenedor"

echo "⏳ Esperando que el contenedor se inicie..."
sleep 10

# Verificar que el contenedor esté funcionando
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ Contenedor iniciado correctamente"
else
    echo "❌ El contenedor no se inició correctamente"
    echo "📋 Logs del contenedor:"
    docker logs $CONTAINER_NAME
    exit 1
fi

echo "🔍 Paso 5: Verificación final..."

# Verificar puerto
if ss -tuln | grep -q ":$PORT"; then
    echo "✅ Puerto $PORT está escuchando"
else
    echo "❌ Puerto $PORT no está escuchando"
    exit 1
fi

# Crear scripts de gestión
echo "📝 Paso 6: Creando scripts de gestión..."

# Script de conexión
cat > ~/connect.sh << 'EOF'
#!/bin/bash
echo "🚀 Conectando al servidor de desarrollo..."
echo "==========================================" 
echo ""
echo "📋 Servicios disponibles:"
echo "   🌐 VS Code Web: http://localhost:8443"
echo "   🔑 Password: dev123"
echo "   🖥️  Terminal SSH directo: ssh -p 50493 eramirez@10.14.102.22"
echo ""
echo "🔗 Creando túnel SSH..."
ssh -L 8443:localhost:8443 -p 50493 eramirez@10.14.102.22
EOF

chmod +x ~/connect.sh

# Script de gestión
cat > ~/manage-container.sh << 'EOF'
#!/bin/bash
case "$1" in
    start)
        echo "🚀 Iniciando contenedor..."
        docker start code-server
        ;;
    stop)
        echo "⏹️ Deteniendo contenedor..."
        docker stop code-server
        ;;
    restart)
        echo "🔄 Reiniciando contenedor..."
        docker restart code-server
        ;;
    status)
        echo "📊 Estado del contenedor:"
        docker ps | grep code-server || echo "Contenedor no está ejecutándose"
        ;;
    logs)
        echo "📋 Logs del contenedor:"
        docker logs -f code-server
        ;;
    shell)
        echo "🐚 Accediendo al contenedor..."
        docker exec -it code-server /bin/bash
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs|shell}"
        ;;
esac
EOF

chmod +x ~/manage-container.sh

echo ""
echo "🎉 ¡INSTALACIÓN COMPLETADA EXITOSAMENTE!"
echo "======================================="
echo ""
echo "📋 Información del servidor:"
echo "   🖥️  IP del servidor: $SERVER_IP"
echo "   🚪 Puerto SSH: $SSH_PORT"
echo "   👤 Usuario: $USER"
echo ""
echo "📋 Información del contenedor:"
echo "   🐳 Nombre: $CONTAINER_NAME"
echo "   🌐 Puerto: $PORT"
echo "   🔑 Password: $PASSWORD"
echo "   📁 Workspace: $WORKSPACE_PATH"
echo ""
echo "🚀 Para conectarte desde tu máquina local:"
echo "   1. Ejecuta: ssh -L 8443:localhost:8443 -p $SSH_PORT $USER@$SERVER_IP"
echo "   2. Abre navegador en: http://localhost:8443"
echo "   3. Ingresa password: $PASSWORD"
echo ""
echo "🛠️ Scripts creados:"
echo "   📁 ~/connect.sh - Script de conexión desde máquina local"
echo "   🔧 ~/manage-container.sh - Gestión del contenedor"
echo ""
echo "📖 Comandos útiles:"
echo "   Ver estado: ~/manage-container.sh status"
echo "   Ver logs: ~/manage-container.sh logs"
echo "   Acceder shell: ~/manage-container.sh shell"
echo "   Reiniciar: ~/manage-container.sh restart"
echo ""
echo "🔗 Estado actual del contenedor:"
docker ps | grep $CONTAINER_NAME
echo ""
echo "✅ Todo listo para usar VS Code Server!"
echo "📞 Para soporte, revisa la documentación completa."