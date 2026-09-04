# Persistent history, subscriptions, and push handling

This update adds:

- Persistent history processing (DataController now stores the last NSPersistentHistoryToken in UserDefaults and fetches transactions since that token)
- AppDelegate wired into the SwiftUI app to register for remote notifications and handle incoming CloudKit pushes
- CloudKitManager that checks account status and ensures a basic CKQuerySubscription for "Note" records is present (silent push)

How it works
- When a remote change occurs, CloudKit sends a silent push notification (if subscriptions are configured). AppDelegate receives the push and calls DataController.shared.processPersistentHistoryIfNeeded(), which fetches and applies persistent history transactions.

Notes & next improvements
- You should persist the last known history token after successfully applying transactions; this template stores the token in UserDefaults.
- Consider improving conflict resolution and history handling for large transaction sets (batching, pruning, and resilience).
- Add unit tests and better error handling for production.
