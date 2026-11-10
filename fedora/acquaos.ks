# AcquaOS — Fedora 45 live ISO
# Kickstart per livemedia-creator --no-virt (lorax).
# Base: Fedora 45 (rilasciata 2026-11-03, supporto fino al 2027-12-08).
# Desktop: Cinnamon (spin ufficiale Fedora) + Hyprland (COPR sdegler/hyprland).
# Installer: Calamares (nei repo ufficiali Fedora, 3.3.14).
# I pacchetti sono stati verificati contro i repodata ufficiali Fedora 45
# (Everything + Updates): tutto presente tranne Hyprland e Starship,
# che arrivano da COPR (vedi repo sotto).
#version=DEVEL

# X Window System configuration information
xconfig  --startxonboot

# Keyboard layouts
keyboard 'us'

# System timezone
timezone Europe/Rome

# System language
lang en_US.UTF-8

# Firewall configuration
firewall --enabled --service=mdns

# SELinux configuration
selinux --enforcing

# Repo di base Fedora 45
url --url="https://dl.fedoraproject.org/pub/fedora/linux/releases/45/Everything/x86_64/os/"
# Aggiornamenti (il nome "updates" e riservato ad Anaconda: usare un altro nome)
repo --name="fedora-updates" --baseurl="https://dl.fedoraproject.org/pub/fedora/linux/updates/45/Everything/x86_64/"
# Hyprland: non e nei repo ufficiali Fedora, COPR sdegler/hyprland (ha build per F45)
# (i repo aggiunti via kickstart non verificano la firma GPG: Anaconda li considera attendibili)
repo --name="copr-hyprland" --baseurl="https://download.copr.fedorainfracloud.org/results/sdegler/hyprland/fedora-45-x86_64/"
# Starship: non e nei repo ufficiali Fedora, COPR atim/starship (ha build per F45)
repo --name="copr-starship" --baseurl="https://download.copr.fedorainfracloud.org/results/atim/starship/fedora-45-x86_64/"

# Network information
network  --bootproto=dhcp --device=link --activate

# System services
services --disabled="sshd" --enabled="NetworkManager,ModemManager,livesys,livesys-late"

# livemedia-creator modifications.
shutdown

# System bootloader configuration
bootloader --location=none

# Clear blank disks or all existing partitions
clearpart --all --initlabel

rootpw rootme

# Disk partitioning information
reqpart
part / --size=10240

%post

# enable tmpfs for /tmp
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' --whatprovides system-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

# AcquaOS: display manager SDDM e avvio grafico
systemctl enable sddm.service
systemctl set-default graphical.target
systemctl enable NetworkManager.service

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Remove the rescue kernel and image to save space
# Installation will recreate these on the target
rm -f /boot/*-rescue*

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Live: nessun fstab, dracut gestisce il mount del rootfs
cat /dev/null > /etc/fstab

# Rimuovi la password di root nella live (la gestisce livesys-scripts)
passwd -d root > /dev/null

# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

%end

# Copia le configurazioni Aqua (Hyprland, Waybar, Wofi, fastfetch, starship, SDDM)
# dal checkout del repo. @@REPO_ROOT@@ viene sostituito da
# fedora/build_fedora_iso.sh con il percorso reale del repo.
# %post --nochroot gira sull'host: $INSTALL_ROOT e la root dell'immagine.
%post --nochroot

REPO="@@REPO_ROOT@@"
ROOT="$INSTALL_ROOT"

mkdir -p "$ROOT/etc/skel/.config/hypr" "$ROOT/etc/skel/.config/waybar" \
  "$ROOT/etc/skel/.config/fastfetch" "$ROOT/etc/skel/.config/wofi" \
  "$ROOT/etc/skel/.config" "$ROOT/etc/sddm.conf.d" "$ROOT/etc/acquaos/configs"

cp -a "$REPO/configs/hypr/hyprland.conf" "$ROOT/etc/skel/.config/hypr/hyprland.conf" 2>/dev/null || true
cp -a "$REPO/configs/waybar/config.jsonc" "$ROOT/etc/skel/.config/waybar/config.jsonc" 2>/dev/null || true
cp -a "$REPO/configs/waybar/style.css" "$ROOT/etc/skel/.config/waybar/style.css" 2>/dev/null || true
cp -a "$REPO/configs/fastfetch/config.jsonc" "$ROOT/etc/skel/.config/fastfetch/config.jsonc" 2>/dev/null || true
cp -a "$REPO/configs/wofi/config" "$ROOT/etc/skel/.config/wofi/config" 2>/dev/null || true
cp -a "$REPO/configs/wofi/style.css" "$ROOT/etc/skel/.config/wofi/style.css" 2>/dev/null || true
cp -a "$REPO/configs/starship.toml" "$ROOT/etc/skel/.config/starship.toml" 2>/dev/null || true
cp -a "$REPO/configs/sddm/aquaos.conf" "$ROOT/etc/sddm.conf.d/aquaos.conf" 2>/dev/null || true
cp -a "$REPO/configs" "$ROOT/etc/acquaos/configs" 2>/dev/null || true

echo "AcquaOS Fedora 45" > "$ROOT/etc/acquaos-release"

%end

%packages

@core
@standard
@cinnamon-desktop

# Use https://pagure.io/livesys-scripts to configure the system
livesys-scripts

@anaconda-tools
anaconda
anaconda-install-env-deps
anaconda-live
dracut-config-generic
dracut-live
glibc-all-langpacks
kernel
# Make sure that DNF doesn't pull in debug kernel to satisfy kmod() requires
kernel-modules
kernel-modules-extra

-dracut-config-rescue
-@dial-up
-@input-methods
-gfs2-utils
-gnome-boxes

# --- AcquaOS: base ---
NetworkManager
sudo
nano
bash-completion
grub2-pc
grub2-efi-x64
shim-x64
efibootmgr
os-prober
syslinux
git
curl
wget
unzip
htop

# --- AcquaOS: grafica / X / Wayland ---
xorg-x11-server-Xorg
xorg-x11-xinit
xorg-x11-server-Xwayland

# --- AcquaOS: desktop Cinnamon ---
cinnamon
cinnamon-control-center
cinnamon-screensaver
lightdm
lightdm-gtk

# --- AcquaOS: desktop Hyprland (da COPR sdegler/hyprland) ---
hyprland
xdg-desktop-portal-hyprland
hyprlock
hyprpaper
hyprpolkitagent
hypridle
xdg-desktop-portal
xdg-desktop-portal-gtk

# --- AcquaOS: installer ---
calamares

# --- AcquaOS: extra ---
fastfetch
starship
wofi
sddm
gtk3
glib2
polkit
pipewire
pipewire-alsa
pipewire-pulseaudio
wireplumber
waybar
rofi
kitty
fish
google-noto-sans-fonts
google-noto-emoji-fonts
qt5-qtbase
qt5-qtwayland
qt6-qtbase
qt6-qtwayland
firefox
alsa-utils
pulseaudio
xdg-user-dirs

%end
