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

echo "[1/8] Actualizando sistema..."
sudo pacman -Syu --needed

echo "[2/8] Activando multilib si no está activo..."
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo sed -i '/#\[multilib\]/,/Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf
    sudo pacman -Sy
fi

echo "[3/8] Instalando paquetes base..."
sudo pacman -S --needed - < packages/base.txt

echo "[4/8] Instalando Hyprland y entorno..."
sudo pacman -S --needed - < packages/hyprland.txt

echo "[5/8] Instalando apps..."
sudo pacman -S --needed - < packages/apps.txt

echo "[6/8] Instalando paquetes gaming..."
sudo pacman -S --needed - < packages/gaming.txt

read -rp "¿Instalar drivers NVIDIA? [s/N]: " install_nvidia
if [[ "$install_nvidia" =~ ^[sS]$ ]]; then
    echo "[7/8] Instalando NVIDIA..."
    sudo pacman -S --needed - < packages/nvidia.txt

    sudo mkdir -p /etc/modprobe.d
    echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null

    sudo mkinitcpio -P
else
    echo "[7/8] Saltando NVIDIA..."
fi

echo "[8/8] Copiando dotfiles..."
mkdir -p ~/.config
rsync -av dotfiles/.config/ ~/.config/

echo "Copiando wallpapers..."
sudo mkdir -p /usr/share/backgrounds/rodrikeos
sudo rsync -av assets/wallpapers/ /usr/share/backgrounds/rodrikeos/

echo "Copiando cursores..."
if [ -d assets/cursors ]; then
    sudo mkdir -p /usr/share/icons
    sudo rsync -av assets/cursors/ /usr/share/icons/
fi

read -rp "¿Instalar y activar SDDM con tema Sugar Candy? [s/N]: " install_sddm
if [[ "$install_sddm" =~ ^[sS]$ ]]; then
    echo "Instalando SDDM..."
    sudo pacman -S --needed - < packages/sddm.txt

    echo "Copiando tema Sugar Candy..."
    sudo mkdir -p /usr/share/sddm/themes
    sudo rsync -av sddm/themes/sugar-candy/ /usr/share/sddm/themes/sugar-candy/

    echo "Copiando configuración de SDDM..."
    sudo mkdir -p /etc/sddm.conf.d
    sudo rsync -av sddm/conf.d/ /etc/sddm.conf.d/

    sudo systemctl enable sddm
else
    echo "Saltando SDDM..."
fi

echo "Activando servicios..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

echo "Actualizando carpetas de usuario..."
xdg-user-dirs-update || true

echo
echo "======================================"
echo " Instalación completada."
echo " Reinicia y ejecuta Hyprland."
echo "======================================"
