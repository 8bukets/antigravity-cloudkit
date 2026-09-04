#!/bin/bash
# collect_diagnostics.sh - collect basic logs for debugging
set -e
OUT_DIR="./diagnostics_output"
mkdir -p "$OUT_DIR"
DATE=$(date -u +%Y%m%dT%H%M%SZ)

echo "Collecting diagnostics to $OUT_DIR"

echo "Saving git status..."
git status --porcelain > "$OUT_DIR/git_status_$DATE.txt" || true

echo "Saving latest commits..."
git --no-pager log -n 50 --pretty=format:"%h %ad %s" --date=iso > "$OUT_DIR/commits_$DATE.txt" || true

echo "Done. Attach $OUT_DIR when requesting remote debugging."
