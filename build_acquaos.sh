#!/bin/bash
set -e
echo "--- Build AcquaOS: Minimal Mode ---"

# 1. Installazione strumenti base disponibili su Ubuntu
sudo apt-get update
sudo apt-get install -y arch-install-scripts erofs-utils units libarchive-tools

# 2. Download manuale dei file di configurazione Arch
git clone https://gitlab.archlinux.org/archlinux/archiso.git
mkdir -p releng
cp -r archiso/configs/releng/* releng/

# 3. Creazione lista pacchetti
echo "base linux linux-firmware cinnamon networkmanager sudo" > releng/packages.x86_64

# 4. Configurazione Dark Mode
mkdir -p releng/airootfs/etc/skel/.config/gtk-3.0
echo -e "[Settings]\ngtk-theme-name=Adwaita-dark\ngtk-application-prefer-dark-theme=1" > releng/airootfs/etc/skel/.config/gtk-3.0/settings.ini

# 5. Esecuzione Build
mkdir -p output
sudo mkarchiso -v -w work_dir -o output releng/
