# feature/icloud-wire-ids (placeholder) — migration & wiring notes

This branch is a deliberately-small config-only workspace for wiring production bundle identifier and iCloud/CloudKit container identifiers.

Important: This branch contains ONLY placeholders. Do NOT push real provisioning profiles, private keys, or secrets to this repository.

What to do locally (recommended workflow)

1. Create a local branch from this remote branch:
   git fetch origin
   git checkout -b feature/icloud-wire-ids origin/feature/icloud-wire-ids

2. Replace placeholders:
   - AntigravityCloudKit/ENTITLEMENTS_PLACEHOLDER.entitlements -> AntigravityCloudKit/AntigravityCloudKit.entitlements
     * Replace iCloud.com.example.antigravity.placeholder with your real container id (e.g. iCloud.com.8bukets.antigravity)
   - Update Xcode Target → Signing & Capabilities:
     * Bundle identifier: com.yourcompany.yourapp
     * Select the iCloud capability and ensure the container above is selected

3. Commit only the entitlements and Xcode project/target changes on this branch.
   git add AntigravityCloudKit/AntigravityCloudKit.entitlements
   git commit -m "wire: replace entitlements placeholders with real App & iCloud container IDs"

4. Open a PR from feature/icloud-wire-ids -> feature/icloud-setup. This keeps config changes separate and auditable.

Post-PR checklist (reviewers should verify):
- Entitlements contain the exact container(s) used in Apple Developer Portal.
- Xcode target bundle id matches App ID in Developer Portal.
- Provisioning profiles include iCloud entitlements.
- No private keys, provisioning profiles, or credentials are committed.

Rollout steps after merging into feature/icloud-setup:
- Run full CI and manual device tests.
- Promote CloudKit schema to Production only when ready.

If you'd like, I can generate a local patch you can apply that renames ENTITLEMENTS_PLACEHOLDER.entitlements -> AntigravityCloudKit.entitlements with placeholder TODO comments where to change values. Reply "generate patch".
