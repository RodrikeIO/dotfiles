#!/bin/bash

set -e

if command -v yay >/dev/null 2>&1; then
    echo "yay ya está instalado."
    exit 0
fi

echo "Instalando dependencias para yay..."
sudo pacman -S --needed git base-devel

echo "Clonando yay desde AUR..."
tmpdir="$(mktemp -d)"
cd "$tmpdir"

git clone https://aur.archlinux.org/yay.git
cd yay

echo "Compilando e instalando yay..."
makepkg -si --noconfirm

cd ~
rm -rf "$tmpdir"

echo "yay instalado correctamente."
