#!/bin/bash
set -e
echo "--- Build AcquaOS: Final Fix ---"

# 1. Installazione strumenti di sistema
sudo apt-get update
sudo apt-get install -y arch-install-scripts erofs-utils units libarchive-tools

# 2. Otteniamo mkarchiso direttamente dalla sorgente e lo rendiamo eseguibile
git clone https://gitlab.archlinux.org/archlinux/archiso.git
chmod +x archiso/archiso/mkarchiso

# 3. Preparazione cartelle
mkdir -p releng
cp -r archiso/configs/releng/* releng/

# 4. Lista pacchetti pulita
echo "base linux linux-firmware cinnamon networkmanager sudo" > releng/packages.x86_64

# 5. Dark Mode
mkdir -p releng/airootfs/etc/skel/.config/gtk-3.0
echo -e "[Settings]\ngtk-theme-name=Adwaita-dark\ngtk-application-prefer-dark-theme=1" > releng/airootfs/etc/skel/.config/gtk-3.0/settings.ini

# 6. Esecuzione usando il binario appena scaricato
mkdir -p output
sudo ./archiso/archiso/mkarchiso -v -w work_dir -o output releng/
