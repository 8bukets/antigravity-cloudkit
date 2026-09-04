import Foundation
import CoreData

/// PersistentHistoryProcessor: improved with pruning and simple exponential backoff for retries.
/// This extends the previous implementation with resumable batches, basic pruning hooks, and
/// retry/backoff for transient failures. Still placeholder-first; tune thresholds for your app.
final class PersistentHistoryProcessor {
    private let container: NSPersistentCloudKitContainer
    private let batchSize: Int
    private let tokenKey = "com.8bukets.antigravity.historyToken.v3"
    private let maxRetries = 5

    init(container: NSPersistentCloudKitContainer, batchSize: Int = 50) {
        self.container = container
        self.batchSize = batchSize
    }

    private var lastToken: NSPersistentHistoryToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: tokenKey) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }
        set {
            guard let t = newValue else { UserDefaults.standard.removeObject(forKey: tokenKey); return }
            if let d = try? NSKeyedArchiver.archivedData(withRootObject: t, requiringSecureCoding: true) {
                UserDefaults.standard.set(d, forKey: tokenKey)
            }
        }
    }

    func processHistoryIfNeeded(completion: ((Error?) -> Void)? = nil) {
        processWithRetry(retriesLeft: maxRetries, delay: 1.0, completion: completion)
    }

    private func processWithRetry(retriesLeft: Int, delay: TimeInterval, completion: ((Error?) -> Void)?) {
        fetchAndApplyHistory(after: lastToken) { [weak self] newToken, error in
            if let error = error {
                guard retriesLeft > 0 else { completion?(error); return }
                // Exponential backoff
                let nextDelay = delay * 2
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self?.processWithRetry(retriesLeft: retriesLeft - 1, delay: nextDelay, completion: completion)
                }
                return
            }

            // Successfully processed at least one batch — persist token and attempt to continue if more pending
            if let t = newToken {
                self?.lastToken = t
                // Try to fetch additional batches immediately (resumable)
                self?.fetchAndApplyRemainingBatches(completion: completion)
            } else {
                completion?(nil)
            }
        }
    }

    private func fetchAndApplyRemainingBatches(completion: ((Error?) -> Void)?) {
        // Loop until no more transactions or we hit a sensible limit to avoid CPU starvation
        var iteration = 0
        let maxIterations = 20
        func loop() {
            guard iteration < maxIterations else { completion?(nil); return }
            iteration += 1
            fetchAndApplyHistory(after: lastToken) { [weak self] newToken, error in
                if let error = error { completion?(error); return }
                if let t = newToken {
                    self?.lastToken = t
                    // Continue loop to catch more
                    loop()
                } else {
                    completion?(nil)
                }
            }
        }
        loop()
    }

    private func fetchAndApplyHistory(after token: NSPersistentHistoryToken?, completion: @escaping (NSPersistentHistoryToken?, Error?) -> Void) {
        let bgContext = container.newBackgroundContext()
        bgContext.perform {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
            request.fetchLimit = self.batchSize
            do {
                guard let result = try bgContext.execute(request) as? NSPersistentHistoryResult,
                      let transactions = result.result as? [NSPersistentHistoryTransaction], !transactions.isEmpty else {
                    completion(nil, nil)
                    return
                }

                // Apply transactions to viewContext
                let viewContext = self.container.viewContext
                viewContext.performAndWait {
                    for transaction in transactions {
                        if let changes = transaction.objectIDNotification() {
                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
                        }
                    }
                    do {
                        if viewContext.hasChanges { try viewContext.save() }
                    } catch {
                        print("Failed saving viewContext: \(error)")
                    }
                }

                // Optionally prune history here (placeholder hook)
                self.pruneHistoryIfNeeded(transactions: transactions, context: bgContext)

                // Return last token
                let last = transactions.last?.token
                completion(last, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    private func pruneHistoryIfNeeded(transactions: [NSPersistentHistoryTransaction], context: NSManagedObjectContext) {
        // Placeholder: in production you might delete old history entries or notify the server
        // For example, trim history older than X days. Use NSPersistentHistoryChangeRequest to delete: not shown here.
    }
}
