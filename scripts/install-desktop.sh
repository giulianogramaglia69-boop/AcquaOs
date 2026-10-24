#!/usr/bin/env bash
set -Eeuo pipefail

DESKTOP="${1:-hyprland}"

case "$DESKTOP" in
  hyprland)
    /usr/local/bin/setup-hyprland.sh
    ;;
  cinnamon)
    /usr/local/bin/setup-cinnamon.sh
    ;;
  *)
    echo "Unknown desktop: $DESKTOP"
    echo "Supported: hyprland, cinnamon"
    exit 1
    ;;
esac
