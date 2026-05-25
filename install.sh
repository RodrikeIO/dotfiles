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

read -rp "¿Instalar yay para paquetes de AUR? [s/N]: " install_yay
if [[ "$install_yay" =~ ^[sS]$ ]]; then
    ./scripts/install-yay.sh
else
    echo "Saltando yay..."
fi

echo "[4] Instalando Hyprland y entorno..."
sudo pacman -S --needed - < packages/hyprland.txt

echo "[5] Instalando apps..."
sudo pacman -S --needed - < packages/apps.txt

echo "[6] Instalando paquetes gaming..."
sudo pacman -S --needed - < packages/gaming.txt

read -rp "¿Aplicar Rodrike Tweaks para gaming/Steam? [s/N]: " rodrike_tweaks
if [[ "$rodrike_tweaks" =~ ^[sS]$ ]]; then
    ./scripts/setup-rodrike-tweaks.sh
else
    echo "Saltando Rodrike Tweaks..."
fi

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
    echo "[11] Instalando SDDM..."
    sudo pacman -S --needed - < packages/sddm.txt

    read -rp "¿Instalar tema Sugar Candy desde AUR? [s/N]: " install_sugar
    if [[ "$install_sugar" =~ ^[sS]$ ]]; then
        if ! command -v yay >/dev/null 2>&1; then
            echo "yay no está instalado. Instalándolo..."
            ./scripts/install-yay.sh
        fi

        echo "Instalando Sugar Candy desde AUR..."
        yay -S --needed sddm-sugar-candy-git

        echo "Configurando SDDM con Sugar Candy..."
        sudo mkdir -p /etc/sddm.conf.d

        sudo tee /etc/sddm.conf.d/theme.conf >/dev/null <<EOF
[Theme]
Current=sugar-candy
CursorTheme=Kana-Arima
CursorSize=24
EOF

        echo "Configurando wallpaper de Sugar Candy..."
        if [ -f /usr/share/sddm/themes/sugar-candy/theme.conf ]; then
            sudo sed -i 's|^Background=.*|Background="/usr/share/backgrounds/rodrikeos/wallpaper.jpg"|' /usr/share/sddm/themes/sugar-candy/theme.conf
        else
            echo "Aviso: no se encontró /usr/share/sddm/themes/sugar-candy/theme.conf"
        fi
    else
        echo "Usando SDDM limpio sin tema Sugar Candy."
    fi

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
