#!/usr/bin/env bash
set -Eeuo pipefail

# AcquaOS ISO builder
# Arch-based live ISO with Calamares installer and desktop selection:
#   - Cinnamon
#   - Hyprland
#
# AquaOS theme is water-inspired: blue, cyan, glass, soft modern UI.
#
# Requires:
#   - Debian/Ubuntu or Arch Linux host
#   - root access

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
fastfetch
starship
wofi
sddm
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
mkdir -p "${PROFILE_DIR}/airootfs/etc/skel/.config/hypr"
mkdir -p "${PROFILE_DIR}/airootfs/etc/skel/.config/waybar"
mkdir -p "${PROFILE_DIR}/airootfs/etc/skel/.config/fastfetch"
mkdir -p "${PROFILE_DIR}/airootfs/etc/skel/.config/wofi"
mkdir -p "${PROFILE_DIR}/airootfs/etc/skel/.config/starship"
mkdir -p "${PROFILE_DIR}/airootfs/etc/sddm.conf.d"
mkdir -p "${PROFILE_DIR}/airootfs/etc/calamares/modules"
mkdir -p "${PROFILE_DIR}/airootfs/etc/acquaos"
mkdir -p "${PROFILE_DIR}/airootfs/usr/local/bin"

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
EOF

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/fastfetch/config.jsonc" <<'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "archlinux",
    "type": "builtin",
    "color": {
      "1": "#6ee7ff",
      "2": "#0ea5e9",
      "3": "#d8f7ff"
    }
  },
  "display": {
    "separator": " -> ",
    "size": {
      "max": 80
    }
  },
  "modules": [
    "title",
    "separator",
    "os",
    "host",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "desktop",
    "wm",
    "memory",
    "break",
    "colors"
  ]
}
EOF

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/starship.toml" <<'EOF'
format = """
[](#1d4f73)
\[$envvar\](bg:#1d4f73 fg:#d8f7ff)
[](bg:#0f3d59 fg:#1d4f73)
\$username\[@\$hostname\](bg:#0f3d59 fg:#d8f7ff)
[](bg:#0b2f42 fg:#0f3d59)
\$directory\n[](fg:#0b2f42 bg:#081b29)
\$git_branch\$git_status
[](fg:#081b29 bg:#071b29)
\$cmd_duration
[](fg:#071b29)
\n$character
"""

right_format = ""

add_newline = true

[character]
success_symbol = "[❯](bold #7ee7ff)"
error_symbol = "[✖](bold red)"

[username]
show_always = true
style_user = "bg:#1d4f73 fg:#d8f7ff"
style_root = "bg:#1d4f73 fg:#fff"
format = "[\u3000$user](bg:#1d4f73 fg:#d8f7ff)"

[hostname]
ssh_only = false
disabled = false
style = "bg:#0f3d59 fg:#d8f7ff"
format = "[@$hostname](bg:#0f3d59 fg:#d8f7ff)"

[directory]
style = "bg:#0f3d59 fg:#d8f7ff"
format = "[ $path ](bg:#0f3d59 fg:#d8f7ff)"
truncation_length = 4
truncation_symbol = "…/"

[git_branch]
style = "bg:#081b29 fg:#7ee7ff"
format = "[ $symbol$branch ](bg:#081b29 fg:#7ee7ff)"

[git_status]
style = "bg:#081b29 fg:#d8f7ff"
format = "[($all_status$ahead_behind)](bg:#081b29 fg:#d8f7ff)"

[cmd_duration]
style = "bg:#071b29 fg:#a7f3d0"
format = "[ ⏱ $duration ](bg:#071b29 fg:#a7f3d0)"
EOF

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/wofi/config" <<'EOF'
mode=drun
allow_images=true
width=520
height=420
location=top_right
xoffset=20
yoffset=40
show=drun
filter_rate=100
insensitive=false
prompt=Launch
key_expand=Tab
EOF

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/wofi/style.css" <<'EOF'
window {
  background: rgba(4, 22, 35, 0.8);
  border: 1px solid rgba(114, 224, 255, 0.7);
  border-radius: 18px;
  color: #d8f7ff;
}

#input {
  background: rgba(9, 47, 66, 0.9);
  color: #d8f7ff;
  border: 1px solid rgba(125, 235, 255, 0.8);
  border-radius: 12px;
  margin: 10px;
  padding: 10px 14px;
  font-size: 14px;
}

#entry {
  background: transparent;
  color: #d8f7ff;
  border-radius: 12px;
  padding: 10px 14px;
}

#entry:selected {
  background: rgba(25, 118, 163, 0.9);
  color: white;
}
EOF

cat > "${PROFILE_DIR}/airootfs/etc/sddm.conf.d/aquaos.conf" <<'EOF'
[General]
Numlock=on

[Theme]
Current=breeze
CursorTheme=Bibata-Modern-Classic
Font=Noto Sans,10,-1,5,50,0,0,0,0,0

[Autologin]
Relogin=false

[Users]
HideUsers=
EOF

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
theme=aqua
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

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/hypr/hyprland.conf" <<'EOF'
# AquaOS Hyprland configuration
# Water-inspired palette: deep blue, teal, cyan, glass panels

$bg_deep = rgb(4, 22, 35)
$bg_mid = rgb(9, 47, 66)
$bg_panel = rgba(9, 52, 74, 0.72)
$bg_panel_alt = rgba(14, 85, 109, 0.75)

$teal = rgb(72, 214, 255)
$cyan = rgb(125, 235, 255)
$ice = rgb(216, 247, 255)
$blue = rgb(18, 117, 163)
$muted = rgb(158, 210, 225)
$shadow = rgba(0, 0, 0, 0.45)

general {
    gaps_in = 6
    gaps_out = 12
    border_size = 2
    col.active_border = rgba(114, 224, 255, 1)
    col.inactive_border = rgba(18, 117, 163, 0.7)
    layout = dwindle
}

decoration {
    rounding = 14
    blur = yes
    blur_size = 7
    blur_passes = 2
    blur_new_optimizations = on

    drop_shadow = yes
    shadow_range = 20
    shadow_render_power = 3
    shadow_color = $shadow

    active_opacity = 1.0
    inactive_opacity = 0.95
    fullscreen_opacity = 1.0
}

animations {
    enabled = yes

    bezier = aqua_curve, 0.05, 0.9, 0.1, 1.0

    animation = windows, 1, 7, aqua_curve
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 8, default
    animation = workspaces, 1, 7, aqua_curve
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    vfr = true
}

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
    sensitivity = 0.0
}

gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

monitor = ,preferred,auto,1

$mainMod = SUPER

bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, B, exec, firefox
bind = $mainMod, R, exec, rofi -show drun
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, F, fullscreen,
bind = $mainMod, V, togglefloating,
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, SPACE, exec, rofi -show drun

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6

bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = opacity 0.96 0.92, class:^(firefox)$
windowrulev2 = opacity 0.96 0.92, class:^(kitty)$

exec-once = dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = waybar
exec-once = nm-applet
exec-once = swaybg -i /usr/share/backgrounds/aquaos-water.jpg -m fill

env = XCURSOR_THEME, Bibata-Modern-Classic
env = XCURSOR_SIZE, 24
env = GTK_THEME, Adwaita-dark

exec-once = hyprctl setcursor Bibata-Modern-Classic 24
EOF

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/waybar/config.jsonc" <<'EOF'
{
  "layer": "top",
  "position": "top",
  "height": 30,
  "spacing": 6,
  "modules-left": ["hyprland/workspaces", "hyprland/window"],
  "modules-center": [],
  "modules-right": ["pulseaudio", "network", "cpu", "memory", "clock"],

  "hyprland/workspaces": {
    "disable-scroll": true,
    "all-outputs": true,
    "format": "{icon}",
    "format-icons": {
      "default": "◉",
      "active": "◉",
      "urgent": "⚡"
    }
  },

  "hyprland/window": {
    "format": "{title}",
    "max-length": 40
  },

  "pulseaudio": {
    "format": "🔊 {volume}%",
    "format-muted": "🔇 muted"
  },

  "network": {
    "format": "🌐 {essid}",
    "format-disconnected": "🌐 offline"
  },

  "cpu": {
    "format": "CPU {usage}%"
  },

  "memory": {
    "format": "RAM {used}G"
  },

  "clock": {
    "format": "🕒 {:%H:%M %d/%m}"
  }
}
EOF

cat > "${PROFILE_DIR}/airootfs/etc/skel/.config/waybar/style.css" <<'EOF'
* {
  font-family: "JetBrains Mono", "Noto Sans", sans-serif;
  border: none;
  border-radius: 12px;
}

window#waybar {
  background: rgba(7, 27, 39, 0.7);
  color: #d8f7ff;
  border-bottom: 1px solid rgba(125, 235, 255, 0.35);
}

#workspaces {
  background: rgba(10, 68, 92, 0.6);
  border-radius: 12px;
  margin: 5px 8px;
  padding: 0 10px;
}

#workspaces button {
  color: #d8f7ff;
  background: transparent;
  padding: 0 10px;
  margin: 0 2px;
}

#workspaces button.active {
  color: #7debff;
  background: rgba(18, 117, 163, 0.8);
  border-radius: 10px;
}

#window, #pulseaudio, #network, #cpu, #memory, #clock {
  padding: 0 12px;
  background: rgba(14, 85, 109, 0.45);
  border-radius: 10px;
  margin: 5px 4px;
}
EOF

mkdir -p "${PROFILE_DIR}/airootfs/usr/share/backgrounds"

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
systemctl enable sddm 2>/dev/null || true
systemctl enable calamares.service 2>/dev/null || true

mkdir -p /etc/skel/Desktop
echo 'Welcome to AcquaOS' > /etc/skel/Desktop/README.txt

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
