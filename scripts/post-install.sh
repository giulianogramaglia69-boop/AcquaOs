#!/usr/bin/env bash
set -Eeuo pipefail

echo "==> AcquaOS post-install setup"

pacman -S --needed --noconfirm \
  base-devel \
  git \
  curl \
  wget \
  unzip \
  p7zip \
  ntfs-3g \
  exfatprogs \
  dosfstools \
  dos2unix \
  file \
  openssh \
  openssl \
  vim \
  nano \
  bash-completion \
  man-db \
  man-pages \
  policykit \
  noto-fonts \
  noto-fonts-emoji \
  ttf-jetbrains-mono \
  ttf-liberation \
  mesa \
  vulkan-radeon \
  vulkan-intel \
  vulkan-nouveau \
  libva-mesa-driver \
  mesa-vdpau \
  networkmanager \
  bluez \
  bluez-utils \
  pipewire \
  pipewire-alsa \
  pipewire-pulse \
  pipewire-jack \
  wireplumber \
  alsa-utils \
  pulseaudio \
  pavucontrol \
  xdg-user-dirs \
  xdg-desktop-portal \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  hyprland \
  waybar \
  rofi \
  kitty \
  wofi \
  starship \
  fastfetch \
  firefox \
  sddm \
  cinnamon \
  lightdm \
  lightdm-gtk-greeter \
  polkit-kde-agent \
  qt5-wayland \
  qt6-wayland \
  qt5-base \
  qt6-base

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sddm
systemctl enable systemd-timesyncd

xdg-user-dirs-update

mkdir -p /home/aqua/.config/hypr
mkdir -p /home/aqua/.config/waybar
mkdir -p /home/aqua/.config/wofi
mkdir -p /home/aqua/.config/fastfetch

cp /etc/acquaos/configs/hypr/hyprland.conf /home/aqua/.config/hypr/hyprland.conf
cp /etc/acquaos/configs/waybar/config.jsonc /home/aqua/.config/waybar/config.jsonc
cp /etc/acquaos/configs/waybar/style.css /home/aqua/.config/waybar/style.css
cp /etc/acquaos/configs/starship.toml /home/aqua/.config/starship.toml
cp /etc/acquaos/configs/fastfetch/config.jsonc /home/aqua/.config/fastfetch/config.jsonc
cp /etc/acquaos/configs/wofi/config /home/aqua/.config/wofi/config
cp /etc/acquaos/configs/wofi/style.css /home/aqua/.config/wofi/style.css

chown -R aqua:aqua /home/aqua/.config

cat > /home/aqua/.bashrc <<'EOF'
# AquaOS shell configuration
export STARSHIP_CONFIG=~/.config/starship.toml
eval "$(starship init bash)"
fastfetch
EOF
chown aqua:aqua /home/aqua/.bashrc

mkdir -p /etc/sddm.conf.d
cp /etc/acquaos/configs/sddm/aquaos.conf /etc/sddm.conf.d/aquaos.conf

echo "==> Post-install done"
echo "Reboot and select your desktop session."
