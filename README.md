# AcquaOS

AcquaOS is an Arch Linux-based live environment built with `archiso`.
It includes a Calamares installer and a desktop choice for:
- Cinnamon
- Hyprland

The Hyprland theme is styled as an AquaOS water-inspired visual identity.
It also includes fastfetch, starship, wofi, and an SDDM configuration.

## Requirements

Run this on a Debian/Ubuntu or Arch Linux host with root access and enough disk space.

## Build

```bash
chmod +x build_acquaos.sh
./build_acquaos.sh
```

The script will:
- install the required host dependencies
- clone `archiso`
- create a `releng` profile
- configure package lists and desktop profiles
- generate a live ISO in `output/`

## Desktop behavior

When the live system starts, AcquaOS can choose between:
- Cinnamon
- Hyprland

Hyprland uses a dedicated AquaOS theme with blue and cyan tones, translucent glass panels, and a clean modern layout.

## Included styling extras

- fastfetch
- starship
- wofi
- SDDM config

## Output

```bash
./output/
```
