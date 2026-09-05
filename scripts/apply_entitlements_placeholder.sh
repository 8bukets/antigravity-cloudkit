#!/usr/bin/env bash
set -e

# apply_entitlements_placeholder.sh
# Copies the ENTITLEMENTS_PLACEHOLDER.entitlements into the Xcode project entitlements file
# and prints explicit TODOs for you to replace locally. This script is safe to run locally only.

SRC="AntigravityCloudKit/ENTITLEMENTS_PLACEHOLDER.entitlements"
DST="AntigravityCloudKit/AntigravityCloudKit.entitlements"

if [ ! -f "$SRC" ]; then
  echo "Error: placeholder file not found at $SRC"
  exit 1
fi

cp "$SRC" "$DST"
chmod 0644 "$DST"

cat <<EOF
WROTE: $DST

IMPORTANT: This file contains placeholder iCloud container identifiers. Before committing:
- Open $DST and replace iCloud.com.example.antigravity.placeholder with your real CloudKit container id(s)
- Update your Xcode target's Signing & Capabilities -> Bundle Identifier to match your App ID
- Do NOT commit provisioning profiles or private keys

Workflow suggestion:
1) Run this script locally to copy the placeholder entitlements
2) Edit $DST to replace placeholders
3) Commit only the entitlements and Xcodeproject changes on a local branch
4) Push the local branch to origin/feature/icloud-wire-ids and open PR -> feature/icloud-setup

EOF
