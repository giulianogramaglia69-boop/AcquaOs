#!/usr/bin/env bash
set -Eeuo pipefail

# AcquaOS ISO builder
# Arch-based live ISO with Calamares installer and desktop choice:
#   - Cinnamon
#   - Hyprland
#
# Runtime:
#   - Debian/Ubuntu or Arch Linux host
#   - root access required

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${REPO_ROOT}/work_dir"
OUTPUT_DIR="${REPO_ROOT}/output"
PROFILE_DIR="${REPO_ROOT}/releng"
ARCHISO_DIR="${REPO_ROOT}/archiso"
PKGLIST_FILE="${REPO_ROOT}/packages.x86_64"

if [[ ${EUID} -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "==> Building AcquaOS"

if command -v pacman >/dev/null 2>&1; then
  echo "==> Detected Arch Linux host"
  ${SUDO} pacman -Syy --noconfirm
  ${SUDO} pacman -S --needed --noconfirm \
    git dosfstools grub xorriso squashfs-tools libarchive mtools gdisk \
    arch-install-scripts base-devel
elif command -v apt-get >/dev/null 2>&1; then
  echo "==> Detected Debian/Ubuntu host"
  ${SUDO} apt-get update
  ${SUDO} apt-get install -y --no-install-recommends \
    git ca-certificates curl wget xz-utils \
    squashfs-tools xorriso libarchive-tools dosfstools \
    grub-pc-bin grub-efi-amd64-bin mtools gdisk \
    arch-install-scripts
else
  echo "Unsupported distro. Use Arch Linux or Debian/Ubuntu."
  exit 1
fi

if [[ ! -d "${ARCHISO_DIR}" ]]; then
  echo "==> Cloning archiso"
  git clone --depth 1 https://gitlab.archlinux.org/archlinux/archiso.git "${ARCHISO_DIR}"
fi

mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}"

if [[ ! -d "${PROFILE_DIR}" ]]; then
  echo "==> Creating releng profile"
  mkdir -p "${PROFILE_DIR}"
  cp -a "${ARCHISO_DIR}/configs/releng/." "${PROFILE_DIR}/"
fi

cat > "${PKGLIST_FILE}" <<'EOF'
base
linux
linux-firmware
networkmanager
sudo
nano
bash-completion
grub
efibootmgr
os-prober
xorg-server
xorg-xinit
lightdm
lightdm-gtk-greeter
cinnamon
hyprland
xdg-desktop-portal
xdg-desktop-portal-hyprland
xdg-desktop-portal-gtk
calamares
calamares-settings
gtk3
glib2
polkit
pipewire
pipewire-alsa
pipewire-pulse
wireplumber
waybar
rofi
kitty
fish
noto-fonts
noto-fonts-emoji
qt5-base
qt5-wayland
qt6-base
qt6-wayland
firefox
alsa-utils
pulseaudio
xdg-user-dirs
EOF

mkdir -p "${PROFILE_DIR}/airootfs/root"
mkdir -p "${PROFILE_DIR}/airootfs/etc/skel/.config/gtk-3.0"

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
EOF

mkdir -p "${PROFILE_DIR}/airootfs/etc/calamares/modules"
mkdir -p "${PROFILE_DIR}/airootfs/etc/calamares/branding"
mkdir -p "${PROFILE_DIR}/airootfs/usr/local/bin"

cat > "${PROFILE_DIR}/airootfs/etc/calamares/modules/desktop-choice.conf" <<'EOF'
desktop: cinnamon
custom_profile: /etc/acquaos/desktop-cinnamon.conf
EOF

cat > "${PROFILE_DIR}/airootfs/etc/acquaos/desktop-cinnamon.conf" <<'EOF'
desktop=cinnamon
packages=(
  "cinnamon"
  "lightdm"
  "lightdm-gtk-greeter"
  "networkmanager"
  "xdg-desktop-portal-gtk"
  "pipewire"
  "pipewire-pulse"
  "wireplumber"
)
session=gnome
theme=Adwaita-dark
EOF

cat > "${PROFILE_DIR}/airootfs/etc/acquaos/desktop-hyprland.conf" <<'EOF'
desktop=hyprland
packages=(
  "hyprland"
  "xdg-desktop-portal-hyprland"
  "xdg-desktop-portal-gtk"
  "waybar"
  "rofi"
  "kitty"
  "polkit"
  "pipewire"
  "pipewire-pulse"
  "wireplumber"
)
session=hyprland
theme=tokyo-night
EOF

cat > "${PROFILE_DIR}/airootfs/usr/local/bin/acquaos-desktop-selector.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -f /etc/acquaos/desktop-selected ]]; then
  exit 0
fi

if ! command -v whiptail >/dev/null 2>&1; then
  echo "cinnamon" > /etc/acquaos/desktop-selected
  exit 0
fi

CHOICE=$(whiptail --title "AcquaOS Desktop Selection" --menu "Choose your desktop environment" 16 60 2 \
  "1" "Cinnamon" \
  "2" "Hyprland" 3>&1 1>&2 2>&3 || true)

mkdir -p /etc/acquaos

case "${CHOICE}" in
  1)
    echo "cinnamon" > /etc/acquaos/desktop-selected
    cp /etc/acquaos/desktop-cinnamon.conf /etc/acquaos/desktop.conf
    ;;
  2)
    echo "hyprland" > /etc/acquaos/desktop-selected
    cp /etc/acquaos/desktop-hyprland.conf /etc/acquaos/desktop.conf
    ;;
  *)
    echo "cinnamon" > /etc/acquaos/desktop-selected
    cp /etc/acquaos/desktop-cinnamon.conf /etc/acquaos/desktop.conf
    ;;
esac
EOF
chmod +x "${PROFILE_DIR}/airootfs/usr/local/bin/acquaos-desktop-selector.sh"

cat > "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=us\n' > /etc/vconsole.conf
printf 'acquaos\n' > /etc/hostname

useradd -m -G wheel -s /bin/bash aqua
printf 'aqua:aqua\n' | chpasswd
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel

mkdir -p /etc/acquaos
cp /etc/acquaos/desktop-cinnamon.conf /etc/acquaos/desktop.conf 2>/dev/null || true

systemctl enable NetworkManager
systemctl enable lightdm
systemctl enable systemd-timesyncd
systemctl enable calamares.service 2>/dev/null || true

mkdir -p /etc/skel/Desktop
echo 'Welcome to AcquaOS' > /etc/skel/Desktop/README.txt

# Add a startup helper
cat > /etc/profile.d/acquaos-desktop-chooser.sh <<'EOF2'
#!/usr/bin/env bash
if [[ -x /usr/local/bin/acquaos-desktop-selector.sh ]] && [[ ! -f /etc/acquaos/desktop-selected ]]; then
  /usr/local/bin/acquaos-desktop-selector.sh
fi
EOF2
chmod +x /etc/profile.d/acquaos-desktop-chooser.sh
EOF
chmod +x "${PROFILE_DIR}/airootfs/root/customize_airootfs.sh"

cat > "${PROFILE_DIR}/profiledef.sh" <<'EOF'
#!/usr/bin/env bash
iso_name="acquaos"
iso_label="ACQUAOS_$(date +%Y%m%d)"
iso_publisher="AcquaOS <https://github.com/giulianogramaglia69-boop/AcquaOs>"
iso_application="AcquaOS Live/Install DVD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
authorized_users=('root')
author="AcquaOS"
EOF
chmod +x "${PROFILE_DIR}/profiledef.sh"

if [[ ! -x "${ARCHISO_DIR}/archiso/mkarchiso" ]]; then
  chmod +x "${ARCHISO_DIR}/archiso/mkarchiso"
fi

echo "==> Running mkarchiso"
${SUDO} "${ARCHISO_DIR}/archiso/mkarchiso" -v -w "${WORK_DIR}" -o "${OUTPUT_DIR}" "${PROFILE_DIR}"

echo "==> Done"
echo "ISO output: ${OUTPUT_DIR}"
ls -1 "${OUTPUT_DIR}"