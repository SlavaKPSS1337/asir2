#!/bin/bash

# Verificar si el sistema es Ubuntu 22 o 24
source /etc/os-release
if [[ "$VERSION_ID" != "22.04" && "$VERSION_ID" != "24.04" ]]; then
    echo "Este script solo está probado para Ubuntu 22.04 y 24.04"
    exit 1
fi

# Actualizar paquetes e instalar Squid si no está instalado
apt update
if ! command -v squid &> /dev/null; then
    echo "Instalando Squid..."
    apt install -y squid apache2-utils
fi

# Hacer una copia de seguridad del archivo de configuración original
cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Configurar Squid para permitir el acceso a Internet
cat <<EOL > /etc/squid/squid.conf
acl localnet src 10.0.X.0/24
http_access allow localnet
http_access allow localhost
http_access deny all
http_port 3128
EOL

# Reiniciar Squid para aplicar los cambios
systemctl restart squid

# Crear archivo de lista negra de redes sociales
cat <<EOL > /etc/squid/redes_sociales
facebook.com
twitter.com
instagram.com
tiktok.com
EOL

# Modificar configuración de Squid para bloquear redes sociales
cat <<EOL >> /etc/squid/squid.conf
acl redessociales dstdomain "/etc/squid/redes_sociales"
http_access deny redessociales
EOL

# Reiniciar Squid para aplicar las nuevas reglas
systemctl restart squid

# Configurar autenticación básica con usuarios
htpasswd -c /etc/squid/users usuario1

# Verificar la ruta de basic_ncsa_auth
AUTH_PATH=$(dpkg -L squid | grep basic_ncsa_auth | head -n 1)
if [ -z "$AUTH_PATH" ]; then
    echo "Error: No se encontró el binario basic_ncsa_auth"
    exit 1
fi

# Agregar autenticación a Squid
cat <<EOL >> /etc/squid/squid.conf
auth_param basic program $AUTH_PATH /etc/squid/users
auth_param basic children 5
auth_param basic realm PROXY SAD
acl autenticados proxy_auth REQUIRED
http_access allow autenticados
EOL

# Reiniciar Squid nuevamente
systemctl restart squid

# Fin del script
