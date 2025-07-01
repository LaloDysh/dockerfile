#!/bin/bash

# Script de conexión al servidor de desarrollo
# Autor: Configuración Docker VS Code Server
# Uso: ./connect.sh

echo "🚀 Conectando al servidor de desarrollo..."
echo "===========================================" 
echo ""
echo "📋 Servicios disponibles:"
echo "   🌐 VS Code Web: http://localhost:8443"
echo "   🔑 Password: dev123"
echo "   🖥️  Terminal SSH directo: ssh -p 50493 eramirez@10.14.102.22"
echo ""
echo "📝 Instrucciones:"
echo "   1. Deja esta terminal abierta (mantiene el túnel activo)"
echo "   2. Abre tu navegador en: http://localhost:8443"
echo "   3. Ingresa password: dev123"
echo "   4. Para conectar SSH directo, usa otra terminal"
echo ""
echo "🔗 Creando túnel SSH..."
echo "   Conectando a: eramirez@10.14.102.22:50493"
echo "   Túnel: localhost:8443 -> servidor:8443"
echo ""

# Función para manejar la salida limpia
cleanup() {
    echo ""
    echo "🛑 Cerrando túnel SSH..."
    echo "✅ Desconectado del servidor"
    exit 0
}

# Capturar Ctrl+C para salida limpia
trap cleanup INT

# Crear el túnel SSH
echo "⏳ Estableciendo conexión..."
ssh -L 8443:localhost:8443 -p 50493 eramirez@10.14.102.22

# Si llegamos aquí, la conexión se cerró
cleanup