# Antigravity CloudKit Example

This project is a minimal SwiftUI template demonstrating Core Data syncing with CloudKit (NSPersistentCloudKitContainer), NSUbiquitousKeyValueStore, and a UIDocument example for iCloud Drive.

Replace the placeholder container identifier in AntigravityCloudKit/AntigravityCloudKit.entitlements and DataController.swift with your own CloudKit container (e.g., iCloud.com.yourcompany.app).

Setup:
- Create App ID and enable iCloud with a CloudKit container in the Apple Developer portal.
- In Xcode, set the target's Signing & Capabilities → iCloud and select the container.
- Run on a device signed into iCloud for best results.

Troubleshooting: See the README in the repo for common issues.
