#!/bin/bash

set -e

echo "======================================"
echo " Rodrike Dotfiles Installer"
echo "======================================"
echo

if ! command -v pacman >/dev/null 2>&1; then
    echo "Este instalador está pensado para Arch Linux o derivadas."
    exit 1
fi

echo "[1] Actualizando sistema..."
sudo pacman -Syu --needed

echo "[2] Activando multilib si no está activo..."
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo sed -i '/#\[multilib\]/,/Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf
    sudo pacman -Sy
fi

echo "[3] Instalando paquetes base..."
sudo pacman -S --needed - < packages/base.txt

echo "[4] Instalando Hyprland y entorno..."
sudo pacman -S --needed - < packages/hyprland.txt

echo "[5] Instalando apps..."
sudo pacman -S --needed - < packages/apps.txt

echo "[6] Instalando paquetes gaming..."
sudo pacman -S --needed - < packages/gaming.txt

read -rp "¿Instalar drivers NVIDIA? [s/N]: " install_nvidia
if [[ "$install_nvidia" =~ ^[sS]$ ]]; then
    echo "[7] Instalando NVIDIA..."
    sudo pacman -S --needed - < packages/nvidia.txt

    echo "Configurando NVIDIA DRM modeset..."
    sudo mkdir -p /etc/modprobe.d
    echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null

    echo "Regenerando initramfs..."
    sudo mkinitcpio -P
else
    echo "[7] Saltando NVIDIA..."
fi

echo "[8] Copiando dotfiles..."
mkdir -p ~/.config
rsync -av dotfiles/.config/ ~/.config/

echo "[9] Copiando wallpapers..."
sudo mkdir -p /usr/share/backgrounds/rodrikeos
sudo rsync -av assets/wallpapers/ /usr/share/backgrounds/rodrikeos/

echo "[10] Copiando cursores..."
if [ -d assets/cursors ]; then
    sudo mkdir -p /usr/share/icons
    sudo rsync -av assets/cursors/ /usr/share/icons/
fi

read -rp "¿Instalar y activar SDDM como login gráfico? [s/N]: " install_sddm
if [[ "$install_sddm" =~ ^[sS]$ ]]; then
    echo "[11] Instalando SDDM limpio..."
    sudo pacman -S --needed - < packages/sddm.txt

    echo "Activando SDDM..."
    sudo systemctl enable sddm
else
    echo "[11] Saltando SDDM..."
fi

echo "[12] Activando servicios del sistema..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

echo "[13] Activando servicios de audio..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber || true

echo "[14] Actualizando carpetas de usuario..."
xdg-user-dirs-update || true

echo
echo "======================================"
echo " Instalación completada."
echo "======================================"
echo
echo "Si instalaste SDDM, reinicia y entra en la sesión Hyprland."
echo "Si no instalaste SDDM, inicia Hyprland desde TTY con:"
echo "  Hyprland"
echo
