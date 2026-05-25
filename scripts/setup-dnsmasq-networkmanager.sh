#!/bin/bash

set -e

echo "======================================"
echo " Rodrike DNS Tweaks"
echo " NetworkManager + dnsmasq"
echo "======================================"
echo

sudo pacman -S --needed dnsmasq networkmanager dnsutils

echo "Desactivando systemd-resolved para evitar conflictos..."
sudo systemctl disable --now systemd-resolved 2>/dev/null || true

echo "Configurando NetworkManager para usar dnsmasq..."
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/dns.conf >/dev/null <<EOF
[main]
dns=dnsmasq
EOF

echo "Configurando caché de dnsmasq..."
sudo mkdir -p /etc/NetworkManager/dnsmasq.d
sudo tee /etc/NetworkManager/dnsmasq.d/cache.conf >/dev/null <<EOF
cache-size=1000
no-negcache
EOF

echo "Recreando /etc/resolv.conf temporal..."
sudo tee /etc/resolv.conf >/dev/null <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

echo "Reiniciando NetworkManager..."
sudo systemctl restart NetworkManager

echo
echo "Comprobando configuración..."
cat /etc/resolv.conf
pgrep -a dnsmasq || true
nslookup store.steampowered.com || true

echo
echo "======================================"
echo " Rodrike DNS Tweaks aplicados."
echo "======================================"
