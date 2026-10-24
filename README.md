# AcquaOS

AcquaOS is an Arch Linux-based live environment built with `archiso`.
It includes a Calamares installer and a desktop choice for:
- Cinnamon
- Hyprland

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

Hyprland uses a dedicated custom config profile, while Cinnamon uses the default Cinnamon setup.

## Output

```bash
./output/
```
