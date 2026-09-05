#!/usr/bin/env bash
set -e

git fetch origin
git checkout feature/cloudkit-server-examples

# Add files
git add scripts examples swift .github README_CLOUDKIT_SERVER.md || true

git commit -m "chore: add CloudKit server examples (JWT scripts, client wrapper, swift token store, GH Action, README)" || true

git push origin feature/cloudkit-server-examples
