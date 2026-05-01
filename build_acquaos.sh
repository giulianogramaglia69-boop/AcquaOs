#!/bin/bash
set -e
echo "--- Build di Emergenza AcquaOS ---"

# 1. Installazione strumenti necessari
sudo apt-get update
sudo apt-get install -y arch-install-scripts erofs-utils units libarchive-tools archiso[span_2](start_span)[span_2](end_span)

# 2. Setup struttura (Reset totale)
rm -rf releng work_dir output
mkdir -p releng
cp -r /usr/share/archiso/configs/releng/* releng/ || true[span_3](start_span)[span_3](end_span)

# 3. FIX ERRORE 2: Creazione file critici se mancanti
mkdir -p releng/airootfs/etc/
[ -f releng/pacman.conf ] || touch releng/pacman.conf[span_4](start_span)[span_4](end_span)

# 4. Inserimento pacchetti
if [ -f "packages.x86_64" ]; then
    cat packages.x86_64 >> releng/packages.x86_64
else
    echo "base linux linux-firmware cinnamon" > releng/packages.x86_64[span_5](start_span)[span_5](end_span)
fi

# 5. Personalizzazioni (Dark Mode & Always On)
mkdir -p releng/airootfs/etc/skel/.config/gtk-3.0
echo -e "[Settings]\ngtk-theme-name=Adwaita-dark\ngtk-application-prefer-dark-theme=1" > releng/airootfs/etc/skel/.config/gtk-3.0/settings.ini[span_6](start_span)[span_6](end_span)

mkdir -p releng/airootfs/etc/systemd/
echo -e "[Login]\nHandleLidSwitch=ignore\nIdleAction=ignore" > releng/airootfs/etc/systemd/logind.conf[span_7](start_span)[span_7](end_span)

# 6. Avvio Build con pulizia cache
mkdir -p output
sudo mkarchiso -v -w work_dir -o output releng/[span_8](start_span)[span_8](end_span)
