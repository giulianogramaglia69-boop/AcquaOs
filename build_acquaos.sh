#!/bin/bash

# 1. Crea le cartelle necessarie nella ISO
mkdir -p build/etc/skel/.config/gtk-3.0
mkdir -p build/etc/systemd/
mkdir -p out

# 2. Imposta il DARK MODE (Il look di AcquaOS)
echo "[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1" > build/etc/skel/.config/gtk-3.0/settings.ini

# 3. Imposta l'ALWAYS ON (Niente sospensione)
echo -e "[Login]\nHandleLidSwitch=ignore\nIdleAction=ignore" > build/etc/systemd/logind.conf

# 4. Crea l'identità di AcquaOS (Quello che leggi nel terminale)
echo 'NAME="AcquaOS"
ID=acquaos
ID_LIKE=arch
PRETTY_NAME="AcquaOS Crystal"
ANSI_COLOR="0;34"' > build/etc/os-release

echo "Configurazione AcquaOS completata con successo!"
