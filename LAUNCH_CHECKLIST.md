# Launch Readiness Checklist — antigravity-cloudkit

Living document, updated by the `daily-launch-prep` skill on each scheduled
run. Newest entries at the top of each section.

## Reliability

### Done
- 2026-09-14/15: Root-caused and fixed a long-standing CI crash ("Test
  crashed with signal trap/abrt before establishing connection") after
  5+ earlier rounds of speculative fixes (ruby-version, simulator
  destination, key-path syntax, private init, Notification misuse,
  CloudKit setup guards) didn't resolve it. Actual cause:
  `ContentView.swift`'s `@FetchRequest` used `NSManagedObject.entity()`
  (the abstract base class, no corresponding model entity) instead of
  `Note.entity()` — crashed the test host app immediately at launch.
  Fixed in commit `8012308`; CI run `34828832956` passed (~10.5 min,
  vs. 165–500s crashes on every prior attempt). PR #1 is green and
  mergeable as of 2026-09-14.

### Open
- No local Swift/Xcode toolchain exists in the daily-run sandbox — every
  Swift-touching change can only be validated via pushed CI, never
  locally. Keep this in mind before claiming a fix "works."

## Security
_(nothing tracked — no secrets, no deployed service, reference app only)_

## Infra

### Done
- XcodeGen (`project.yml`) generates the Xcode project; CI installs
  XcodeGen and runs `xcodegen generate` before building.

---
_This checklist was seeded on 2026-09-15 based on the 2026-09-13/14
session's findings; it is not itself an autonomous run's output._
