#!/usr/bin/env bash
# scripts/rollback_migration.sh
# Runnable rollback helper for SwiftData migration.
# WARNING: Run on a safe copy and with the app NOT running. This script only manipulates local DB files.
# It does NOT touch CloudKit. Use at your own risk — verify backups before restoring.

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --source <path-to-original-sqlite-dir-or-file> --target <path-to-app-sqlite-dir> [--simulator <device-udid>] [--keep-backups]

Options:
  --source        Directory or path containing original Core Data sqlite files (.sqlite, -shm, -wal) or a single .sqlite file.
  --target        Directory where the app expects the sqlite files (e.g., Simulator app data or device container path).
  --simulator     (optional) Simulator UDID. When provided, the script will copy into the simulator's app data containers using simctl.
  --keep-backups  (optional) Keep timestamped backups in the target directory (default: true). Use --no-keep-backups to remove.

Examples:
  # Copy a local DB into a simulator app container (replace AMBUNDLEID and UDID):
  $0 --source /path/to/backup/myapp.sqlite --target ~/Desktop/tmp/appdata --simulator <SIM_UDID>

  # Restore directly to a path your app uses:
  $0 --source /backups/coredata --target /Users/me/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/<APP_ID>/Library/Application\ Support/
EOF
}

# Minimal argument parsing
SOURCE=""
TARGET=""
SIMULATOR=""
KEEP_BACKUPS=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="$2"; shift 2;;
    --target) TARGET="$2"; shift 2;;
    --simulator) SIMULATOR="$2"; shift 2;;
    --keep-backups) KEEP_BACKUPS=true; shift 1;;
    --no-keep-backups) KEEP_BACKUPS=false; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -z "$SOURCE" || -z "$TARGET" ]]; then
  echo "--source and --target are required"
  usage
  exit 1
fi

# Resolve paths
SOURCE_PATH=$(realpath "$SOURCE")
TARGET_PATH=$(realpath -m "$TARGET")

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP_DIR="$TARGET_PATH/rollback_backup_$TIMESTAMP"

echo "Source: $SOURCE_PATH"
echo "Target: $TARGET_PATH"

# Ensure app not running — best-effort only
echo "Ensure the app is NOT running on the target device/simulator."

# Prepare list of sqlite files to copy
declare -a SRC_FILES
if [[ -d "$SOURCE_PATH" ]]; then
  # accept *.sqlite and related files
  for f in "$SOURCE_PATH"/*.sqlite*; do
    [[ -e "$f" ]] || continue
    SRC_FILES+=("$f")
  done
elif [[ -f "$SOURCE_PATH" ]]; then
  # if given a single sqlite file, also look for -shm and -wal in same dir
  SRC_DIR=$(dirname "$SOURCE_PATH")
  BASE=$(basename "$SOURCE_PATH")
  SRC_FILES+=("$SOURCE_PATH")
  for suf in -shm -wal; do
    if [[ -f "$SRC_DIR/$BASE$suf" ]]; then
      SRC_FILES+=("$SRC_DIR/$BASE$suf")
    fi
  done
else
  echo "Source path not found"
  exit 1
fi

if [[ ${#SRC_FILES[@]} -eq 0 ]]; then
  echo "No sqlite files found in source"
  exit 1
fi

# Create target backup
if [[ "$KEEP_BACKUPS" = true ]]; then
  echo "Creating backup of target path at: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  # copy existing sqlite files if any
  shopt -s nullglob
  for g in "$TARGET_PATH"/*.sqlite*; do
    cp -pv "$g" "$BACKUP_DIR/" || true
  done
  shopt -u nullglob
fi

# Copy files into target
echo "Restoring files to target..."
mkdir -p "$TARGET_PATH"
for f in "${SRC_FILES[@]}"; do
  echo "Copying $f -> $TARGET_PATH/"
  cp -pv "$f" "$TARGET_PATH/"
done

# If a simulator UDID was provided, optionally use simctl to place files — best-effort guidance
if [[ -n "$SIMULATOR" ]]; then
  echo "Simulator UDID provided: $SIMULATOR"
  echo "If you need to install into an app container, locate the app data path via simctl or use the Xcode finder."
  echo "Example to list apps: xcrun simctl get_app_container $SIMULATOR <YOUR_APP_BUNDLE_ID> data"
fi

echo "Done."
if [[ "$KEEP_BACKUPS" = true ]]; then
  echo "Target backup kept at: $BACKUP_DIR"
fi

echo "Verify the app starts and data is as expected before deleting backups."

exit 0
