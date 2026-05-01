#!/bin/bash
set -e
echo "--- Inizio Build Reale AcquaOS Crystal ---"

# 1. Installazione strumenti (Fix: libarchive-tools fornisce bsdtar)
sudo apt-get update
sudo apt-get install -y arch-install-scripts erofs-utils units libarchive-tools archiso[span_1](start_span)[span_1](end_span)

# 2. Pulizia e Setup della struttura Archiso
rm -rf releng work_dir output
mkdir -p releng
cp -r /usr/share/archiso/configs/releng/* releng/ || true[span_2](start_span)[span_2](end_span)

# 3. Inserimento della tua lista pacchetti
if [ -f "packages.x86_64" ]; then
    cat packages.x86_64 >> releng/packages.x86_64
else
    echo "ERRORE: packages.x86_64 non trovato!" && exit 1[span_3](start_span)[span_3](end_span)
fi

# 4. Applicazione personalizzazioni (Dark Mode & Always On)
mkdir -p releng/airootfs/etc/skel/.config/gtk-3.0
mkdir -p releng/airootfs/etc/systemd/

# Dark Mode (Preferenze utente applicate silenziosamente)
echo "[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1" > releng/airootfs/etc/skel/.config/gtk-3.0/settings.ini[span_4](start_span)[span_4](end_span)

# Always On (Configurazione sistema)
echo -e "[Login]\nHandleLidSwitch=ignore\nIdleAction=ignore" > releng/airootfs/etc/systemd/logind.conf[span_5](start_span)[span_5](end_span)

# Identità OS
echo 'NAME="AcquaOS"
ID=acquaos
ID_LIKE=arch
PRETTY_NAME="AcquaOS Crystal"
ANSI_COLOR="0;34"' > releng/airootfs/etc/os-release[span_6](start_span)[span_6](end_span)

# 5. Generazione della ISO
mkdir -p output
sudo mkarchiso -v -w work_dir -o output releng/[span_7](start_span)[span_7](end_span)

echo "--- Build Completata con Successo! ---"
