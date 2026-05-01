#!/bin/bash
set -e
echo "--- Inizio Build Reale AcquaOS Crystal ---"

# 1. Installazione strumenti necessari sul server
sudo apt-get update
sudo apt-get install -y arch-install-scripts erofs-utils units bsdtar

# 2. Setup della struttura Archiso
mkdir -p releng
cp -r /usr/share/archiso/configs/releng/* releng/ || true

# 3. Inserimento della tua lista pacchetti
cat packages.x86_64 >> releng/packages.x86_64

# 4. Applicazione personalizzazioni (Dark Mode & Always On)
mkdir -p releng/airootfs/etc/skel/.config/gtk-3.0
mkdir -p releng/airootfs/etc/systemd/

echo "[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1" > releng/airootfs/etc/skel/.config/gtk-3.0/settings.ini

echo -e "[Login]\nHandleLidSwitch=ignore\nIdleAction=ignore" > releng/airootfs/etc/systemd/logind.conf

# 5. Generazione della ISO
mkdir -p output
sudo mkarchiso -v -w work_dir -o output releng/
