# Antigravity Mission

## System Mission
antigravity-cloudkit is a reference implementation of CloudKit + Core Data
sync (`NSPersistentCloudKitContainer`), `NSUbiquitousKeyValueStore`, and
UIDocument/iCloud Drive patterns for iOS apps in the 8bukets ecosystem. It
exists to give downstream apps — and the autonomous agents building them —
a known-good, CI-tested starting point for iCloud sync features, rather
than each app reinventing this integration from scratch.

## Stakeholders
- Primary Owner <keser.filip@gmail.com>
- Strategic Partner <8bukets@gmail.com>

## Strategic Goals
1. Keep the CloudKit/Core Data reference implementation buildable and
   tested — `xcodebuild test` green on every change, not just `build`.
2. Document iCloud/CloudKit integration patterns clearly enough that other
   agents (Jules, Gemini, Claude) can extend them safely without
   reintroducing the class of bugs this repo shipped with before it had
   real CI (see git history: key-path typos, non-existent API members,
   a private initializer XCTest couldn't reach, CloudKit setup crashing
   automated test runs).
3. Stay aligned with the wider Antigravity ecosystem's conventions —
   agent cooperation rules, PII redaction, no committed secrets.
