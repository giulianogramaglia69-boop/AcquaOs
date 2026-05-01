#!/bin/bash
set -e
echo "--- Build AcquaOS Crystal: Fix Sintassi ---"

# 1. Installazione strumenti
sudo apt-get update
sudo apt-get install -y arch-install-scripts erofs-utils units libarchive-tools archiso

# 2. Setup struttura
rm -rf releng work_dir output
mkdir -p releng
cp -r /usr/share/archiso/configs/releng/* releng/ || true

# 3. Configurazione pacchetti (Fissiamo la lista qui per sicurezza)
echo "base
linux
linux-firmware
cinnamon
networkmanager
sudo" > releng/packages.x86_64

# 4. Personalizzazioni
mkdir -p releng/airootfs/etc/skel/.config/gtk-3.0
echo "[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1" > releng/airootfs/etc/skel/.config/gtk-3.0/settings.ini

# 5. Generazione ISO
mkdir -p output
sudo mkarchiso -v -w work_dir -o output releng/

echo "--- Build Completata! ---"
