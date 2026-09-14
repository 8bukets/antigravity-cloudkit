# Antigravity Integration Rules

1. **The Xcode project is generated, not committed**: `AntigravityCloudKit.xcodeproj`
   is produced by `xcodegen generate` from `project.yml` (see README) and is
   gitignored. Never hand-edit or commit the generated project file — edit
   `project.yml` instead, then regenerate.
2. **CI must stay real**: `xcodebuild test` builds *and runs* the test
   suite on every push (`.github/workflows/ci.yml`). Don't reduce this to
   a build-only check, skip tests, or mark them as expected-to-fail to
   force green — root-cause failures instead, as prior commits on this
   repo did for the pre-existing bugs CI first caught.
3. **No live CloudKit in automated test runs**: `DataController` detects
   an XCTest host (`isRunningTests`, keyed off `XCTestConfigurationFilePath`)
   and skips `cloudKitContainerOptions` in that case, since CI has no real
   Apple Developer Team or signed-in iCloud account. Preserve this when
   extending the persistence layer — don't reintroduce an unconditional
   CloudKit container setup that only works on a real device.
4. **Collaborative workflow**: This repo is part of the Jules–Antigravity
   bridge. Any agent (Jules, Gemini, Claude) working here should leave the
   working tree in a state another agent can pick up cleanly — small,
   well-described commits, no half-finished renames, and a fix for each CI
   failure it introduces before handing off.
5. **Security**: Never commit real iCloud container identifiers,
   provisioning profiles, `.env` values, or API keys. The container
   identifier (`iCloud.com.8bukets.antigravity`) and entitlements in this
   repo are placeholders by design — see the README's "Quick start" for
   what a real integration must replace before shipping.
