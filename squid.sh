#!/bin/bash

# Actualizar paquetes e instalar Squid
apt update && apt install -y squid apache2-utils

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

# Agregar autenticación a Squid
cat <<EOL >> /etc/squid/squid.conf
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/users
auth_param basic children 5
auth_param basic realm PROXY SAD
acl autenticados proxy_auth REQUIRED
http_access allow autenticados
EOL

# Reiniciar Squid nuevamente
systemctl restart squid

# Fin del script
