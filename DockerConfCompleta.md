# VS Code Server Docker - Configuración Completa

## 🎯 Descripción

Este proyecto configura un entorno de desarrollo VS Code Server usando Docker, accesible via web desde cualquier navegador. Incluye scripts automatizados para instalación, gestión y solución de problemas.

## 📋 Estructura de Archivos

```
📁 vs-code-server-docker/
├── 📄 README.md                 # Este archivo
├── 📄 documentation.md          # Documentación completa
├── 📄 troubleshooting.md        # Guía de solución de problemas
├── 🔧 quick-setup.sh           # Instalación automática
├── 🔧 manage-container.sh      # Gestión del contenedor
├── 🔧 connect.sh              # Script de conexión (para máquina local)
└── 🔧 diagnostic.sh           # Script de diagnóstico
```

## 🚀 Instalación Rápida

### En el servidor (10.14.102.22)

```bash
# 1. Descargar archivos (copiar los scripts proporcionados)
# 2. Dar permisos de ejecución
chmod +x *.sh

# 3. Ejecutar instalación automática
./quick-setup.sh
```

### En tu máquina local

```bash
# Crear script de conexión
cat > connect.sh << 'EOF'
#!/bin/bash
echo "🚀 Conectando al servidor de desarrollo..."
echo "🌐 VS Code Web: http://localhost:8443"
echo "🔑 Password: dev123"
ssh -L 8443:localhost:8443 -p 50493 eramirez@10.14.102.22
EOF

chmod +x connect.sh
```

## 📖 Uso Diario

### Conectarse al entorno de desarrollo

1. **Desde tu máquina local:**
   ```bash
   ./connect.sh
   ```

2. **Abrir VS Code en navegador:**
   - URL: `http://localhost:8443`
   - Password: `dev123`

### Gestionar el contenedor (en el servidor)

```bash
# Ver estado
./manage-container.sh status

# Iniciar/detener
./manage-container.sh start
./manage-container.sh stop

# Ver logs
./manage-container.sh logs

# Acceder al shell del contenedor
./manage-container.sh shell
```

## ⚙️ Configuración

### Información del Servidor
- **IP**: 10.14.102.22
- **Puerto SSH**: 50493
- **Usuario**: eramirez

### Información del Contenedor
- **Nombre**: code-server
- **Puerto interno**: 8443
- **Password**: dev123
- **Workspace**: /var/www/html/universe-stable

### Archivos de Configuración
- **Docker**: lscr.io/linuxserver/code-server:latest
- **Volumen**: `/var/www/html/universe-stable:/config/workspace`
- **Reinicio**: automático (unless-stopped)

## 🔧 Comandos Útiles

### Docker
```bash
# Ver contenedores
docker ps

# Ver logs en tiempo real
docker logs -f code-server

# Acceder al contenedor
docker exec -it code-server /bin/bash

# Reiniciar contenedor
docker restart code-server
```

### Red y Conectividad
```bash
# Verificar puertos
ss -tuln | grep 8443

# Verificar firewall
sudo firewall-cmd --list-ports

# Test de conectividad
ping 10.14.102.22
telnet 10.14.102.22 8443
```

### Permisos
```bash
# Arreglar permisos del workspace
sudo chown -R $(id -u):$(id -g) /var/www/html/universe-stable

# Dentro del contenedor
docker exec code-server chown -R $PUID:$PGID /config/workspace
```

## 🚨 Solución de Problemas

### Problemas Comunes

1. **Timeout de conexión**
   ```bash
   # Verificar firewall
   sudo firewall-cmd --add-port=8443/tcp --permanent
   sudo firewall-cmd --reload
   ```

2. **Contenedor no inicia**
   ```bash
   # Recrear contenedor
   ./manage-container.sh recreate
   ```

3. **No se pueden editar archivos**
   ```bash
   # Arreglar permisos
   sudo chown -R $(id -u):$(id -g) /var/www/html/universe-stable
   ```

4. **VS Code no carga**
   ```bash
   # Verificar logs
   docker logs code-server
   
   # Recrear túnel SSH
   ./connect.sh
   ```

### Script de Diagnóstico
```bash
./diagnostic.sh
```

## 📚 Documentación Adicional

- **📄 documentation.md**: Documentación completa paso a paso
- **📄 troubleshooting.md**: Guía detallada de solución de problemas
- **🔧 Scripts**: Comentarios detallados en cada script

## 🔄 Procedimientos de Mantenimiento

### Backup del Workspace
```bash
# Crear backup
sudo tar -czf backup-workspace-$(date +%Y%m%d).tar.gz /var/www/html/universe-stable

# Restaurar backup
sudo tar -xzf backup-workspace-YYYYMMDD.tar.gz -C /
```

### Actualizar Imagen Docker
```bash
# Hacer backup primero
sudo cp -r /var/www/html/universe-stable /tmp/backup-workspace

# Actualizar imagen
docker pull lscr.io/linuxserver/code-server:latest

# Recrear contenedor
./manage-container.sh recreate
```

### Limpieza del Sistema
```bash
# Limpiar Docker
docker system prune -f

# Limpiar logs
sudo journalctl --vacuum-time=7d
```

## 🔐 Seguridad

### Cambiar Password por Defecto
```bash
# Editar script y cambiar PASSWORD="dev123"
nano manage-container.sh

# O recrear contenedor con nuevo password
docker run -d \
  --name code-server \
  -e PASSWORD="tu_nuevo_password" \
  [resto de parámetros...]
```

### Restricciones de Firewall
```bash
# Permitir solo IPs específicas
sudo firewall-cmd --permanent --add-rich-rule='rule source address="tu.ip.local.0/24" port port="8443" protocol="tcp" accept'
sudo firewall-cmd --reload
```

## 📞 Soporte

### Información del Sistema
```bash
# Generar reporte de diagnóstico
./diagnostic.sh > system-report.txt
```

### Logs Importantes
- **Contenedor**: `docker logs code-server`
- **Sistema**: `sudo journalctl -u docker`
- **SSH**: `sudo journalctl -u sshd`
- **Firewall**: `sudo firewall-cmd --list-all`

## 🎉 ¡Listo para Usar!

Con esta configuración tienes:
- ✅ VS Code accesible desde navegador
- ✅ Workspace persistente
- ✅ Scripts de gestión automatizados
- ✅ Documentación completa
- ✅ Solución de problemas integrada

**Para comenzar:**
1. Ejecuta `./quick-setup.sh` en el servidor
2. Ejecuta `./connect.sh` desde tu máquina local  
3. Abre `http://localhost:8443` en tu navegador
4. ¡Comienza a desarrollar!