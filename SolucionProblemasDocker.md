# 🔧 Guía de Solución de Problemas

## 🚨 Problemas Comunes y Soluciones

### 1. Timeout de Conexión

**Síntomas:**
```
ssh: connect to host 10.14.102.22 port XXXX: Operation timed out
telnet: connect to address 10.14.102.22: Operation timed out
```

**Diagnóstico paso a paso:**

```bash
# 1. Verificar conectividad básica
ping 10.14.102.22

# 2. Verificar que el servidor SSH esté funcionando
telnet 10.14.102.22 50493

# 3. Verificar firewall en el servidor
sudo firewall-cmd --list-ports | grep 8443
sudo firewall-cmd --list-ports | grep 50493

# 4. Verificar iptables
sudo iptables -L INPUT -n -v | grep -E "(8443|50493)"
```

**Soluciones:**

#### A. Problema de Firewall
```bash
# Abrir puertos necesarios
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --add-port=50493/tcp --permanent
sudo firewall-cmd --reload

# Verificar que se aplicaron
sudo firewall-cmd --list-ports
```

#### B. Problema de iptables
```bash
# Ver reglas actuales
sudo iptables -L INPUT -n -v

# Si hay reglas REJECT al final, agregar ACCEPT antes
sudo iptables -I INPUT -p tcp --dport 8443 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 50493 -j ACCEPT

# Guardar reglas (varía según sistema)
sudo iptables-save > /etc/iptables/rules.v4
```

#### C. SSH no está funcionando
```bash
# Verificar estado SSH
sudo systemctl status sshd

# Si no está activo
sudo systemctl start sshd
sudo systemctl enable sshd

# Verificar configuración
sudo nano /etc/ssh/sshd_config
# Asegurar que incluye: Port 50493

# Reiniciar SSH
sudo systemctl restart sshd
```

### 2. Puerto ya en uso

**Error:**
```
Bind to port 8443 on 0.0.0.0 failed: Address already in use
```

**Diagnóstico:**
```bash
# Ver qué proceso usa el puerto
sudo netstat -tlnp | grep :8443
sudo lsof -i :8443
sudo ss -tlnp | grep :8443
```

**Soluciones:**

#### A. Detener proceso conflictivo
```bash
# Si es otro contenedor Docker
docker ps | grep 8443
docker stop [CONTAINER_NAME]

# Si es un proceso del sistema
sudo kill -9 [PID]
```

#### B. Cambiar puerto del contenedor
```bash
# Usar puerto alternativo
docker run -d \
  --name code-server \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e PASSWORD="dev123" \
  -p 8444:8443 \
  -v "/var/www/html/universe-stable:/config/workspace" \
  --restart unless-stopped \
  lscr.io/linuxserver/code-server:latest

# Actualizar túnel SSH
ssh -L 8444:localhost:8444 -p 50493 eramirez@10.14.102.22
```

### 3. Contenedor no inicia

**Error:**
```
docker: Error response from daemon: ...
```

**Diagnóstico:**
```bash
# Ver logs detallados
docker logs code-server

# Ver todos los contenedores
docker ps -a

# Verificar imagen
docker images | grep code-server
```

**Soluciones:**

#### A. Problema de permisos
```bash
# Verificar que el usuario esté en grupo docker
groups $USER | grep docker

# Si no está, agregarlo
sudo usermod -aG docker $USER
# Reiniciar sesión después
```

#### B. Problema de espacio en disco
```bash
# Verificar espacio disponible
df -h

# Limpiar Docker si es necesario
docker system prune -f
docker image prune -f
```

#### C. Recrear contenedor desde cero
```bash
# Eliminar contenedor problemático
docker stop code-server 2>/dev/null
docker rm code-server 2>/dev/null

# Eliminar imagen corrupta
docker rmi lscr.io/linuxserver/code-server:latest

# Descargar imagen nuevamente
docker pull lscr.io/linuxserver/code-server:latest

# Recrear contenedor
./manage-container.sh recreate
```

### 4. No se pueden editar archivos

**Síntomas:**
- VS Code muestra archivos como solo lectura
- Error al guardar archivos
- No aparecen archivos en el workspace

**Diagnóstico:**
```bash
# Verificar permisos del directorio
ls -la /var/www/html/universe-stable

# Verificar montaje del volumen
docker inspect code-server | grep -A 10 Mounts
```

**Soluciones:**

#### A. Problema de permisos del host
```bash
# Dar permisos apropiados al directorio
sudo chown -R $(id -u):$(id -g) /var/www/html/universe-stable
sudo chmod -R 755 /var/www/html/universe-stable

# Verificar
ls -la /var/www/html/universe-stable
```

#### B. Problema de permisos dentro del contenedor
```bash
# Acceder al contenedor
docker exec -it code-server /bin/bash

# Dentro del contenedor
chown -R $PUID:$PGID /config/workspace
chmod -R 755 /config/workspace

# Salir
exit
```

#### C. Recrear contenedor con permisos correctos
```bash
# Obtener UID y GID correctos
echo "UID: $(id -u), GID: $(id -g)"

# Recrear contenedor
docker stop code-server
docker rm code-server

docker run -d \
  --name code-server \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e PASSWORD="dev123" \
  -p 8443:8443 \
  -v "/var/www/html/universe-stable:/config/workspace" \
  --restart unless-stopped \
  lscr.io/linuxserver/code-server:latest
```

### 5. VS Code Web no carga

**Síntomas:**
- La página no carga en localhost:8443
- Error de conexión en el navegador
- El túnel SSH se conecta pero VS Code no responde

**Diagnóstico:**
```bash
# Verificar que el túnel SSH esté activo
ps aux | grep "ssh.*8443"

# Verificar desde el servidor que VS Code esté respondiendo
curl -I http://localhost:8443

# Verificar logs del contenedor
docker logs code-server | tail -20
```

**Soluciones:**

#### A. Recrear túnel SSH
```bash
# Matar procesos SSH existentes
pkill -f "ssh.*8443"

# Crear nuevo túnel
ssh -L 8443:localhost:8443 -p 50493 eramirez@10.14.102.22
```

#### B. Problema con el contenedor
```bash
# Verificar que el contenedor esté healthy
docker exec code-server ps aux | grep code-server

# Reiniciar contenedor
docker restart code-server

# Esperar y verificar logs
sleep 10
docker logs code-server | tail -10
```

#### C. Problema de red local
```bash
# Probar con otro puerto local
ssh -L 8444:localhost:8443 -p 50493 eramirez@10.14.102.22

# Acceder en navegador a localhost:8444
```

### 6. Password no funciona

**Síntomas:**
- VS Code rechaza el password "dev123"
- Pantalla de login en bucle

**Diagnóstico:**
```bash
# Verificar variable de entorno
docker exec code-server env | grep PASSWORD

# Verificar configuración
docker exec code-server cat /config/.config/code-server/config.yaml
```

**Soluciones:**

#### A. Recrear contenedor con password correcto
```bash
docker stop code-server
docker rm code-server

docker run -d \
  --name code-server \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e PASSWORD="dev123" \
  -p 8443:8443 \
  -v "/var/www/html/universe-stable:/config/workspace" \
  --restart unless-stopped \
  lscr.io/linuxserver/code-server:latest
```

#### B. Configurar password manualmente
```bash
# Acceder al contenedor
docker exec -it code-server /bin/bash

# Editar configuración
nano /config/.config/code-server/config.yaml

# Buscar línea "password:" y cambiar valor
# Reiniciar contenedor después
exit
docker restart code-server
```

## 🔍 Comandos de Diagnóstico Rápido

### Script de diagnóstico completo
```bash
#!/bin/bash
echo "🔍 DIAGNÓSTICO DEL SISTEMA"
echo "========================="

echo "📡 1. Conectividad de red:"
ping -c 3 8.8.8.8

echo -e "\n🖥️ 2. Información del servidor:"
echo "IP del servidor: $(ip route get 1 | awk '{print $7}' | head -1)"
echo "Hostname: $(hostname)"

echo -e "\n🐳 3. Estado de Docker:"
docker --version
docker ps | grep code-server || echo "Contenedor code-server no encontrado"

echo -e "\n🔥 4. Estado del firewall:"
sudo firewall-cmd --list-ports | grep -E "(8443|50493)" || echo "Puertos no encontrados en firewall"

echo -e "\n🌐 5. Puertos escuchando:"
ss -tuln | grep -E ":(8443|50493|22)"

echo -e "\n📁 6. Directorio de trabajo:"
ls -la /var/www/html/universe-stable | head -5

echo -e "\n🔧 7. Servicios del sistema:"
systemctl is-active docker
systemctl is-active sshd

echo -e "\n✅ Diagnóstico completado"
```

## 📞 Procedimiento de Recuperación de Emergencia

Si nada funciona, usa este procedimiento paso a paso:

### 1. Backup y limpieza completa
```bash
# Hacer backup de archivos importantes
sudo cp -r /var/www/html/universe-stable /tmp/backup-workspace

# Detener y eliminar todo lo relacionado con Docker
docker stop $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null
docker system prune -af
```

### 2. Verificar sistema base
```bash
# Reiniciar servicios básicos
sudo systemctl restart docker
sudo systemctl restart sshd

# Verificar firewall
sudo firewall-cmd --reload
```

### 3. Instalación desde cero
```bash
# Usar script de instalación rápida
./quick-setup.sh
```

### 4. Restaurar backup
```bash
# Restaurar archivos de trabajo
sudo cp -r /tmp/backup-workspace/* /var/www/html/universe-stable/
sudo chown -R $(id -u):$(id -g) /var/www/html/universe-stable
```

## 📧 Información de Contacto para Soporte

Si los problemas persisten:

1. **Recopilar información del sistema:**
   ```bash
   ./diagnóstico.sh > diagnostic-report.txt
   ```

2. **Incluir logs relevantes:**
   ```bash
   docker logs code-server > container-logs.txt
   sudo journalctl -u docker > docker-service-logs.txt
   ```

3. **Proporcionar detalles del error específico y pasos que llevaron al problema**