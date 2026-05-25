#!/bin/bash

set -e

echo "======================================"
echo " Rodrike Tweaks"
echo "======================================"
echo

if ! command -v pacman >/dev/null 2>&1; then
    echo "Este script está pensado para Arch Linux o derivadas."
    exit 1
fi

echo "[1] Instalando paquetes base de rendimiento/gaming..."
sudo pacman -S --needed \
    steam \
    power-profiles-daemon \
    gamemode lib32-gamemode \
    mangohud lib32-mangohud \
    gamescope \
    protontricks \
    vulkan-tools \
    mesa-utils

echo "[2] Activando power-profiles-daemon..."
sudo systemctl enable --now power-profiles-daemon || true

echo "[3] Aplicando ajustes de rendimiento del sistema..."
sudo tee /etc/sysctl.d/99-rodrike-tweaks.conf >/dev/null <<EOF
# Rodrike Tweaks - system performance settings

vm.swappiness = 100
vm.vfs_cache_pressure = 50

net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

sudo sysctl --system

echo "[4] Creando wrapper rodrike-performance..."
sudo tee /usr/local/bin/rodrike-performance >/dev/null <<'EOF'
#!/usr/bin/env bash

# Rodrike performance wrapper
# Pone el sistema en modo performance mientras se ejecuta el juego/app.

if ! command -v powerprofilesctl >/dev/null 2>&1; then
    exec "$@"
fi

if ! powerprofilesctl list | grep -q 'performance:'; then
    exec "$@"
fi

old_profile="$(powerprofilesctl get 2>/dev/null || true)"

powerprofilesctl set performance 2>/dev/null || true

"$@"
exit_code=$?

if [ -n "$old_profile" ]; then
    powerprofilesctl set "$old_profile" 2>/dev/null || true
fi

exit "$exit_code"
EOF

sudo chmod +x /usr/local/bin/rodrike-performance

echo
echo "======================================"
echo " Rodrike Tweaks aplicados."
echo "======================================"
echo
echo "Para Steam puedes usar esta opción de lanzamiento en juegos:"
echo "  rodrike-performance %command%"
echo
echo "No se ha creado steam_dev.cfg."
echo
