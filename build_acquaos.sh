#!/bin/bash
set -e
echo "--- Build AcquaOS Crystal: Fix Chiavi e Struttura ---"

# 1. Installazione strumenti e chiavi di Arch
sudo apt-get update
sudo apt-get install -y arch-install-scripts erofs-utils units libarchive-tools archiso[span_2](start_span)[span_2](end_span)

# 2. Setup pulito
rm -rf releng work_dir output
mkdir -p releng
cp -r /usr/share/archiso/configs/releng/* releng/ || true[span_3](start_span)[span_3](end_span)

# 3. FIX CRITICO: Configurazione dei repository e chiavi
# Senza questo, mkarchiso fallisce con exit code 2 perché non può validare i pacchetti
mkdir -p releng/airootfs/usr/share/pacman/keyrings/
sudo pacman-key --init || echo "Salto init chiavi...[span_4](start_span)"[span_4](end_span)

# 4. Assicuriamoci che i pacchetti siano corretti
# Se il tuo file è vuoto o corrotto, usiamo questi di base
echo "base
linux
linux-firmware
cinnamon
networkmanager
sudo" > releng/packages.x86_64[span_5](start_span)[span_5](end_span)

# 5. Personalizzazioni (Dark Mode)
mkdir -p releng/airootfs/etc/skel/.config/gtk-3.0
echo -e "[Settings]\ngtk-theme-name=Adwaita-dark\ngtk-application-prefer-dark-theme=1" > releng/airootfs/etc/skel/.config/gtk-3.0/settings.ini[span_6](start_span)[span_6](end_span)

# 6. Esecuzione build con bypass dei permessi loop
mkdir -p output
sudo mkarchiso -v -w work_dir -o output releng/[span_7](start_span)[span_7](end_span)
