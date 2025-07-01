# Configuración Docker VS Code Server - Documentación Completa

## 📋 Información del Servidor
- **IP del servidor**: `10.14.102.22`
- **Puerto SSH del servidor**: `50493`
- **Usuario**: `eramirez`

## 🚀 Configuración Inicial desde Cero

### 1. Requisitos Previos

#### En el servidor (10.14.102.22):
```bash
# Verificar que Docker esté instalado
docker --version

# Si no está instalado:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Reiniciar sesión después de agregar al grupo docker
```

#### Configurar Firewall:
```bash
# Verificar puertos abiertos
sudo firewall-cmd --list-ports

# Abrir puerto para VS Code
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --reload

# Verificar que el puerto esté abierto
sudo firewall-cmd --list-ports | grep 8443
```

### 2. Crear Contenedor VS Code Server

```bash
# Comando para crear el contenedor
sudo docker run -d \
  --name code-server \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e PASSWORD="dev123" \
  -p 8443:8443 \
  -v "/var/www/html/universe-stable:/config/workspace" \
  --restart unless-stopped \
  lscr.io/linuxserver/code-server:latest
```

### 3. Verificar Instalación

```bash
# Ver estado del contenedor
docker ps | grep code-server

# Ver logs del contenedor
docker logs code-server

# Verificar que el puerto esté escuchando
ss -tuln | grep 8443

# Debería mostrar:
# tcp LISTEN 0 128 *:8443 *:*
```

## 🔗 Conexión desde Máquina Local

### 1. Crear Túnel SSH

```bash
# Desde tu máquina local
ssh -L 8443:localhost:8443 -p 50493 eramirez@10.14.102.22
```

### 2. Acceder a VS Code

Abrir navegador en: `http://localhost:8443`
- **Password**: `dev123`

## 🛠️ Scripts de Gestión

### Script de Conexión Rápida (connect.sh)

```bash
#!/bin/bash
echo "🚀 Conectando al servidor de desarrollo..."
echo "📋 Servicios disponibles:"
echo "   VS Code Web: http://localhost:8443 (password: dev123)"
echo "   Terminal SSH: en otra terminal ejecuta 'ssh -p 50493 eramirez@10.14.102.22'"
echo ""
echo "🔗 Creando túnel SSH..."
ssh -L 8443:localhost:8443 -p 50493 eramirez@10.14.102.22
```

### Script de Gestión del Contenedor (manage-container.sh)

```bash
#!/bin/bash

case "$1" in
    start)
        echo "🚀 Iniciando contenedor..."
        sudo docker start code-server
        sudo docker ps | grep code-server
        ;;
    stop)
        echo "⏹️ Deteniendo contenedor..."
        sudo docker stop code-server
        ;;
    restart)
        echo "🔄 Reiniciando contenedor..."
        sudo docker restart code-server
        sudo docker ps | grep code-server
        ;;
    status)
        echo "📊 Estado del contenedor:"
        sudo docker ps | grep code-server || echo "Contenedor no está ejecutándose"
        ;;
    logs)
        echo "📋 Logs del contenedor:"
        docker logs -f code-server
        ;;
    shell)
        echo "🐚 Accediendo al contenedor..."
        docker exec -it code-server /bin/bash
        ;;
    remove)
        echo "🗑️ Eliminando contenedor..."
        sudo docker stop code-server 2>/dev/null
        sudo docker rm code-server
        ;;
    recreate)
        echo "🔧 Recreando contenedor..."
        sudo docker stop code-server 2>/dev/null
        sudo docker rm code-server 2>/dev/null
        sudo docker run -d \
          --name code-server \
          -e PUID=$(id -u) \
          -e PGID=$(id -g) \
          -e PASSWORD="dev123" \
          -p 8443:8443 \
          -v "/var/www/html/universe-stable:/config/workspace" \
          --restart unless-stopped \
          lscr.io/linuxserver/code-server:latest
        echo "✅ Contenedor recreado"
        sudo docker ps | grep code-server
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs|shell|remove|recreate}"
        echo ""
        echo "Comandos disponibles:"
        echo "  start    - Iniciar contenedor"
        echo "  stop     - Detener contenedor"
        echo "  restart  - Reiniciar contenedor"
        echo "  status   - Ver estado del contenedor"
        echo "  logs     - Ver logs del contenedor"
        echo "  shell    - Acceder al shell del contenedor"
        echo "  remove   - Eliminar contenedor"
        echo "  recreate - Recrear contenedor desde cero"
        exit 1
        ;;
esac
```

## 🔧 Solución de Problemas

### Problema: Timeout de Conexión

**Síntomas:**
```
ssh: connect to host 10.14.102.22 port XXXX: Operation timed out
telnet: connect to address 10.14.102.22: Operation timed out
```

**Soluciones:**

1. **Verificar conectividad básica:**
   ```bash
   ping 10.14.102.22
   ```

2. **Verificar firewall en el servidor:**
   ```bash
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --add-port=8443/tcp --permanent
   sudo firewall-cmd --reload
   ```

3. **Verificar que el contenedor esté ejecutándose:**
   ```bash
   docker ps | grep code-server
   sudo netstat -tlnp | grep 8443
   ```

4. **Verificar iptables:**
   ```bash
   sudo iptables -L INPUT -n -v | grep -E "(ACCEPT|DROP|REJECT)"
   ```

5. **Si el problema persiste, usar SSH directo del servidor:**
   ```bash
   # Configurar SSH en puerto alternativo
   sudo nano /etc/ssh/sshd_config
   # Agregar: Port 50493
   sudo systemctl restart sshd
   ```

### Problema: Puerto ya en uso

**Error:**
```
Bind to port XXXX on 0.0.0.0 failed: Address already in use
```

**Solución:**
```bash
# Ver qué proceso usa el puerto
sudo netstat -tlnp | grep :8443
sudo lsof -i :8443

# Detener proceso conflictivo
sudo kill -9 [PID]

# O cambiar puerto del contenedor
sudo docker run -d \
  --name code-server \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e PASSWORD="dev123" \
  -p 8444:8443 \
  -v "/var/www/html/universe-stable:/config/workspace" \
  --restart unless-stopped \
  lscr.io/linuxserver/code-server:latest
```

### Problema: Permisos de archivos

**Error:** No se pueden editar archivos

**Solución:**
```bash
# Dar permisos al directorio de trabajo
sudo chown -R $(id -u):$(id -g) /var/www/html/universe-stable

# Desde dentro del contenedor
docker exec -it code-server /bin/bash
chown -R $PUID:$PGID /config/workspace
```

## 📝 Comandos de Referencia Rápida

### Gestión Básica
```bash
# Ver contenedores
docker ps || docker ps -a

# Logs en tiempo real
docker logs -f code-server

# Acceder al contenedor
docker exec -it code-server /bin/bash

# Verificar puertos
ss -tuln | grep 8443
sudo firewall-cmd --list-ports
```

### Conexión desde Local
```bash
# Túnel SSH simple
ssh -L 8443:localhost:8443 -p 50493 eramirez@10.14.102.22

# SSH directo al servidor
ssh -p 50493 eramirez@10.14.102.22

# Verificar conectividad
ping 10.14.102.22
telnet 10.14.102.22 8443
```

## 🎯 Configuración VS Code Local (Opcional)

Si prefieres usar VS Code Desktop:

### ~/.ssh/config
```
Host dev-server
    HostName 10.14.102.22
    User eramirez
    Port 50493
    LocalForward 8443 localhost:8443

Host dev-server-direct
    HostName localhost
    User eramirez
    Port 2222
    ProxyJump dev-server
```

## 🔄 Procedimiento de Recuperación Completa

Si necesitas configurar todo desde cero:

1. **Instalar Docker** (si no está instalado)
2. **Configurar firewall** para puerto 8443
3. **Crear contenedor** con el comando principal
4. **Verificar funcionamiento** local
5. **Crear túnel SSH** desde máquina local
6. **Acceder vía navegador** a localhost:8443

## 📞 Información de Contacto y Configuración

- **Servidor**: 10.14.102.22:50493
- **VS Code Web**: localhost:8443 (via túnel)
- **Password VS Code**: dev123
- **Directorio de trabajo**: /var/www/html/universe-stable
- **Contenedor**: lscr.io/linuxserver/code-server:latest