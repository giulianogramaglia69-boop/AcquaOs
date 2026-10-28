#!/usr/bin/env bash
set -Eeuo pipefail

# Install or enable Caelestia Shell in a Hyprland-based AcquaOS install.
# This is intentionally resilient: it uses an AUR helper if available,
# otherwise it prints a clear message and exits cleanly instead of failing the
# rest of the desktop setup.

if command -v caelestia-shell >/dev/null 2>&1; then
  echo "==> Caelestia Shell already installed"
  exit 0
fi

if command -v yay >/dev/null 2>&1; then
  echo "==> Installing Caelestia Shell with yay"
  yay -S --noconfirm caelestia-shell
  exit 0
fi

if command -v paru >/dev/null 2>&1; then
  echo "==> Installing Caelestia Shell with paru"
  paru -S --noconfirm caelestia-shell
  exit 0
fi

echo "==> No AUR helper found; installing yay first and then Caelestia Shell"
if ! command -v git >/dev/null 2>&1; then
  pacman -S --needed --noconfirm git base-devel
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

git clone https://aur.archlinux.org/yay-bin.git "${TMP_DIR}/yay-bin"
(cd "${TMP_DIR}/yay-bin" && makepkg -si --noconfirm)

if command -v yay >/dev/null 2>&1; then
  yay -S --noconfirm caelestia-shell
else
  echo "==> Caelestia Shell could not be installed automatically."
  echo "==> Please install yay or paru and run: yay -S caelestia-shell"
  exit 1
fi
