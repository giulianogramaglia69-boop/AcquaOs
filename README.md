# AcquaOS

AcquaOS is an Arch Linux-based live environment built with `archiso`.

## Prerequisites

Run this on a Debian/Ubuntu or Arch Linux host with root access and enough disk space.

## Build

```bash
chmod +x build_acquaos.sh
./build_acquaos.sh
```

The build script will:

- install the required Arch ISO build dependencies
- clone `archiso`
- create a `releng` profile
- set up package lists and boot configuration
- generate a live ISO in the `output/` directory

## Output

```bash
./output/
```

This produces a real Arch-based live ISO, not a placeholder script.
