# Best practices & comparison (summary of inspected repos)

This file summarizes best practices for NSPersistentCloudKitContainer and CloudKit+CoreData integration, derived from Apple's sample and other community projects.

1) Set cloudKitContainerOptions before loadPersistentStores
   - This is critical. If you set cloudKitContainerOptions after loading stores, CloudKit syncing won't be configured.

2) Enable NSPersistentHistoryTracking & remote change notifications
   - Use NSPersistentHistoryChangeRequest to fetch history and merge changes into the viewContext.

3) Persist the last NSPersistentHistoryToken
   - Store tokens securely (UserDefaults is acceptable for many apps). Always persist after successful application of changes.

4) Batch history processing
   - Fetch transactions in batches (e.g., 50) to avoid memory spikes for large transaction logs.

5) Conflict resolution
   - Use merge policies for simple apps. For domain-specific rules, implement conflict resolvers (see ConflictResolver.swift) to pick authoritative fields.

6) Subscriptions & silent pushes
   - Create CKQuerySubscription for important record types to receive silent pushes and schedule history processing. Register for remote notifications and call your history processor from the push handler.

7) Testing & environments
   - Use CloudKit Dashboard's Development environment for testing. Promote schema to Production once validated.
   - Test on real devices with iCloud accounts; simulators are less reliable for iCloud features.

8) Sharing
   - Use CKShare with UICloudSharingController to support collaborative/shareable objects. Map Core Data objects to CKRecordIDs carefully and create shares with the proper root record.

References
- apple/sample-cloudkit-coredatasync: https://github.com/apple/sample-cloudkit-coredatasync
- ryanashcraft/CloudSyncSession: https://github.com/ryanashcraft/CloudSyncSession
- johnfairh/TMLPersistentContainer: https://github.com/johnfairh/TMLPersistentContainer
- imtherb91/CoreDataCloudKit: https://github.com/imtherb91/CoreDataCloudKit

