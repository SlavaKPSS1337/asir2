#!/bin/bash

# Verificar si el sistema es Ubuntu 22 o 24
source /etc/os-release
if [[ "$VERSION_ID" != "22.04" && "$VERSION_ID" != "24.04" ]]; then
    echo "Este script solo está probado para Ubuntu 22.04 y 24.04"
    exit 1
fi

# Instalar iptables si no está instalado
if ! command -v iptables &> /dev/null; then
    echo "Instalando iptables..."
    apt update && apt install -y iptables
fi

# Limpiar posibles configuraciones previas del cortafuegos
iptables -F
iptables -X
iptables -t nat -F
iptables -t mangle -F

# Establecer política restrictiva por defecto
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Aceptar cualquier conexión por la interfaz local (localhost)
iptables -A INPUT -i lo -j ACCEPT

# Permitir tráfico web (HTTP y HTTPS) y DNS desde la red interna hacia el exterior
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p udp --dport 53 -j ACCEPT

# Redirigir tráfico web y SSH entrante en eth0 al servidor interno (10.0.X.3)
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 10.0.X.3:80
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 22 -j DNAT --to-destination 10.0.X.3:22
iptables -A FORWARD -p tcp --dport 80 -d 10.0.X.3 -j ACCEPT
iptables -A FORWARD -p tcp --dport 22 -d 10.0.X.3 -j ACCEPT

# Permitir reenvío de tráfico web y SSH desde la red externa a la interna (necesario para PREROUTING)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir acceso SSH al cortafuegos solo desde 10.0.X.30
iptables -A INPUT -p tcp --dport 22 -s 10.0.X.30 -j ACCEPT

# Habilitar NAT para que el equipo funcione como router
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward

# Asegurar que el reenvío de paquetes persista tras reinicio
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# Fin del script
