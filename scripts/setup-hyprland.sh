#!/usr/bin/env bash
set -Eeuo pipefail

echo "==> Setting up Hyprland"

mkdir -p /home/aqua/.config/hypr /home/aqua/.config/waybar /home/aqua/.config/wofi /home/aqua/.config/fastfetch

cp /etc/acquaos/configs/hypr/hyprland.conf /home/aqua/.config/hypr/hyprland.conf
cp /etc/acquaos/configs/waybar/config.jsonc /home/aqua/.config/waybar/config.jsonc
cp /etc/acquaos/configs/waybar/style.css /home/aqua/.config/waybar/style.css
cp /etc/acquaos/configs/wofi/config /home/aqua/.config/wofi/config
cp /etc/acquaos/configs/wofi/style.css /home/aqua/.config/wofi/style.css
cp /etc/acquaos/configs/fastfetch/config.jsonc /home/aqua/.config/fastfetch/config.jsonc
cp /etc/acquaos/configs/starship.toml /home/aqua/.config/starship.toml

chown -R aqua:aqua /home/aqua/.config

mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/hyprland.desktop <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hydro-powered tiling Wayland compositor
Exec=/usr/bin/Hyprland
Type=Application
DesktopNames=Hyprland
EOF

echo "==> Hyprland configured"
