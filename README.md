# Antigravity CloudKit — README

This project provides a minimal template for Core Data + CloudKit sync (NSPersistentCloudKitContainer), NSUbiquitousKeyValueStore, UIDocument iCloud Drive examples, CKShare placeholders, diagnostics, and unit tests.

Quick start (placeholders mode)
1. Clone the repo
   git clone https://github.com/8bukets/antigravity-cloudkit.git
2. Open AntigravityCloudKit.xcodeproj in Xcode
3. Replace placeholder iCloud container identifiers:
   - AntigravityCloudKit/DataController.swift
   - AntigravityCloudKit/CloudKitManager.swift
   - AntigravityCloudKit/ShareManager.swift
   - AntigravityCloudKit/CloudSharingController.swift
   - AntigravityCloudKit/AntigravityCloudKit.entitlements
4. Configure your App ID and provisioning profile in Apple Developer Portal.
5. In Xcode, set target Signing & Capabilities -> iCloud and select your container.
6. Run on a real device signed into iCloud.

Files added recently
- PersistentHistoryProcessor.swift — improved batching and token management
- ConflictResolver.swift — example conflict-resolution strategies
- ShareManager.swift + CloudSharingController.swift — CKShare placeholders and UI wrapper
- DocumentBrowserView.swift + SampleDocument.swift — iCloud Drive example UI and document class
- Diagnostics.swift — lightweight logger that writes to Console and app Documents
- .github/workflows/ci.yml — CI workflow to run xcodebuild tests on macOS runners
- BEST_PRACTICES.md — summary of best-practice patterns from sample repos

Next steps (recommended)
- Replace placeholder container identifiers with your real CloudKit container.
- Enhance ConflictResolver with domain-specific rules (e.g., merge field-level or per-entity policies).
- Implement full CKShare flow: map NSManagedObject -> CKRecord.ID, then create CKShare(rootRecord:). Present UICloudSharingController to complete the share.
- Harden error handling and retry logic in CloudKitManager and PersistentHistoryProcessor.

