# SYNC_TEST_PLAN.md

Sync Test Plan — SwiftData + CloudKit

Objective
- Validate migration from Core Data to SwiftData and confirm CloudKit sync correctness (push/fetch, conflict handling, deletes, subscriptions) in staging before production rollout.

Test environment
- macOS with Xcode (same version as CI). Simulator(s) and test devices available.
- Staging CloudKit container (do NOT use production container for tests unless controlled).
- Use a copy of production Core Data sqlite store for migration tests.

Preconditions
- Branch checked out: feature/swift-data-integration
- SwiftData migration tool compiled and runnable against staging DB copy.
- CloudKit entitlements set to the staging container in Xcode.

Test artifacts
- A copy of the original Core Data sqlite files (.sqlite, -shm, -wal) named e.g., coredata_backup.sqlite
- Test accounts for iCloud on devices/simulators (at least two distinct accounts or two devices signed into different iCloud accounts) to simulate multi-client sync.

Test cases

1) Migration smoke test
- Steps:
  - Ensure app NOT running.
  - Run migration tool against staging copy.
  - Open app against migrated SwiftData store.
- Verification:
  - App launches without errors.
  - Note and Project counts match expected values from pre-migration DB.
  - UUIDs preserved for identifiable records.

2) Basic sync round-trip
- Steps:
  - On Device A, create a new Note; push to CloudKit via push API or background sync.
  - On Device B, run fetchChanges until the new note appears.
- Verification:
  - Note appears on Device B with matching id/title/body/modifiedAt.

3) Concurrent edit conflict (Last-Write-Wins)
- Steps:
  - On Device A and Device B, fetch the same Note.
  - Modify content on both devices, saving with different timestamps spaced by a few seconds.
  - Ensure both devices push their changes to CloudKit.
- Verification:
  - The record with the latest modifiedAt wins on subsequent fetches (confirm on both devices).
  - No duplicate records are created.

4) Conflict alternative / manual merge
- Steps:
  - Simulate a conflicting scenario where last-write-wins is not desired.
  - Verify that the app can detect conflicts (e.g., by comparing per-field modifiedAt or using a change vector) and surface a merge UI for manual resolution.
- Verification:
  - Manual merge resolves fields correctly and push reflects merged result.

5) Delete handling
- Steps:
  - Delete a Note on Device A and push.
  - Verify Device B either receives a deletion record or handles missing record gracefully on next fetch.
- Verification:
  - Record is removed on Device B or marked archived per app policy.

6) Offline edits and reconciliation
- Steps:
  - Put Device B offline, edit several notes, then bring Device B online and sync.
- Verification:
  - Changes are uploaded and reconciled without data loss.
  - Timestamps and conflict resolution behave as expected.

7) Subscription notification handling
- Steps:
  - Ensure CKQuerySubscription is active.
  - Make a change on Device A and verify Device B receives a silent push (content-available) and triggers a background fetch.
- Verification:
  - Background fetch triggers fetchChanges and applies updates without user action.

8) Large dataset / performance
- Steps:
  - Populate staging CloudKit with a representative large number of Note records (e.g., thousands).
  - Run fetchChanges from a fresh client and measure time and memory.
- Verification:
  - Sync completes in acceptable time and without excessive memory spikes. Tune batchSize as needed.

9) Partial migration recovery
- Steps:
  - Simulate an interrupted migration (e.g., kill process mid-run) then resume migration.
- Verification:
  - No duplicate records and migration can resume or be safely restarted.

10) Rollback verification
- Steps:
  - Use scripts/rollback_migration.sh to restore original Core Data .sqlite files to app target (simulator or device path).
  - Launch app and verify it still works with pre-migration DB.
- Verification:
  - App functions with original DB; no data corruption.

Acceptance criteria
- All critical tests (1-6, 10) must pass in staging before promoting to production.
- Performance tests (8) must complete within acceptable time for your app's UX.
- A rollback plan validated (script tested) and backups retained until migration is fully validated.

Reporting
- For each test, capture:
  - Steps taken
  - Logs from app and CloudKit (errors, rate-limiting, failures)
  - Screenshots where relevant
  - Time taken for sync operations

Notes and tips
- Use the FileCKTokenStore to observe and reset lastSyncDate during debugging.
- If you require strong merge semantics (not LWW), consider per-field vector clocks, operation-based CRDTs, or server-side merge rules.
- Keep the staging container data isolated from production to avoid accidental leakage.

