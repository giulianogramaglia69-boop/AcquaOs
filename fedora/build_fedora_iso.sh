#!/usr/bin/env bash
# AcquaOS — build della live ISO Fedora 45 con livemedia-creator --no-virt.
# Da lanciare dentro un container fedora:45 privilegiato (vedi workflow GitHub Actions)
# oppure su un host Fedora 45. Produce output/AcquaOS-45-x86_64.iso
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDERED="/tmp/acquaos-45.ks"

echo "==> Rendering kickstart (repo: ${REPO_ROOT})"
sed "s|@@REPO_ROOT@@|${REPO_ROOT}|g" "${REPO_ROOT}/fedora/acquaos.ks" > "${RENDERED}"

if command -v ksvalidator >/dev/null 2>&1; then
  echo "==> Validating kickstart"
  ksvalidator "${RENDERED}"
fi

mkdir -p "${REPO_ROOT}/output"

echo "==> Building live ISO with livemedia-creator --no-virt"
livemedia-creator --make-iso --no-virt \
  --ks="${RENDERED}" \
  --project="AcquaOS" \
  --releasever=45 \
  --volid="AcquaOS-45" \
  --iso-name="AcquaOS-45-x86_64.iso" \
  --resultdir="${REPO_ROOT}/output" \
  --logfile="${REPO_ROOT}/output/livemedia.log"

echo "==> Done"
ls -lh "${REPO_ROOT}/output/"
