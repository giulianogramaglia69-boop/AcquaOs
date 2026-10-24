#!/usr/bin/env bash
set -Eeuo pipefail

echo "==> Setting up Cinnamon"

mkdir -p /home/aqua/.config

cat > /home/aqua/.config/gtk-3.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
EOF

cat > /home/aqua/.config/gtk-4.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
EOF

chown -R aqua:aqua /home/aqua/.config

echo "==> Cinnamon configured"
