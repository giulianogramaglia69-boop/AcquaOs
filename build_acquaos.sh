#!/usr/bin/env bash
set -Eeuo pipefail

# AcquaOS ISO builder
# Builds an Arch Linux-based live ISO using archiso.
# Requires root on Debian/Ubuntu or Arch Linux.

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

cp "${PKGLIST_FILE}" "${PROFILE_DIR}/packages.x86_64"

mkdir -p "${PROFILE_DIR}/airootfs/root"
mkdir -p "${PROFILE_DIR}/airootfs/etc/skel/.config/gtk-3.0"

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
EOF

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

systemctl enable NetworkManager
systemctl enable lightdm
systemctl enable systemd-timesyncd

mkdir -p /etc/skel/Desktop
echo 'Welcome to AcquaOS' > /etc/skel/Desktop/README.txt
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