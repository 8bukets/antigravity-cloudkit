# SwiftData Migration & CloudKit integration — checklist

- Backup production Core Data persistent store(s).
- Create a staging copy of the DB and test migration there.
- Choose strategy:
  - Dual‑write (safe, incremental) OR
  - One‑time export/import (fast but requires rollback plan)
- Preserve CloudKit metadata if you need to retain CKRecordName/CKShare links.
- Test on multiple devices and with CloudKit Dashboard.
- Promote to Production only after verifying schema and sync behavior.
- Rollback plan: keep original DB and steps to re-enable Core Data stack if needed.
