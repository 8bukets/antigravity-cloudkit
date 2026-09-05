import Foundation
import CoreData

/// PersistentHistoryProcessor: improved with jittered exponential backoff and TokenStore-backed tokens.
final class PersistentHistoryProcessor {
    private let container: NSPersistentCloudKitContainer
    private let batchSize: Int
    private let tokenStore: TokenStore
    private let maxRetries = 5

    init(container: NSPersistentCloudKitContainer, batchSize: Int = 50, tokenStore: TokenStore = TokenStore()) {
        self.container = container
        self.batchSize = batchSize
        self.tokenStore = tokenStore
    }

    private var lastToken: NSPersistentHistoryToken? {
        get { tokenStore.loadToken() }
        set { tokenStore.saveToken(newValue) }
    }

    func processHistoryIfNeeded(completion: ((Error?) -> Void)? = nil) {
        processWithRetry(retriesLeft: maxRetries, baseDelay: 1.0, completion: completion)
    }

    private func processWithRetry(retriesLeft: Int, baseDelay: TimeInterval, completion: ((Error?) -> Void)?) {
        fetchAndApplyHistory(after: lastToken) { [weak self] newToken, error in
            guard let self = self else { return }
            if let error = error {
                guard retriesLeft > 0 else { completion?(error); return }
                // Exponential backoff with jitter
                let jitter = Double.random(in: 0...0.5)
                let delay = baseDelay * pow(2.0, Double(self.maxRetries - retriesLeft)) * (1 + jitter)
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.processWithRetry(retriesLeft: retriesLeft - 1, baseDelay: baseDelay, completion: completion)
                }
                return
            }

            if let t = newToken {
                self.lastToken = t
                // Continue fetching remaining batches, but avoid tight loops
                self.fetchAndApplyRemainingBatches(completion: completion)
            } else {
                completion?(nil)
            }
        }
    }

    private func fetchAndApplyRemainingBatches(completion: ((Error?) -> Void)?) {
        var iteration = 0
        let maxIterations = 50
        func loop() {
            guard iteration < maxIterations else { completion?(nil); return }
            iteration += 1
            fetchAndApplyHistory(after: lastToken) { [weak self] newToken, error in
                if let error = error { completion?(error); return }
                if let t = newToken {
                    self?.lastToken = t
                    // small delay between batches to allow system breathing
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { loop() }
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

                // Prune history older than a threshold (placeholder: 30 days)
                self.pruneHistoryIfNeeded(before: Calendar.current.date(byAdding: .day, value: -30, to: Date()))

                let last = transactions.last?.token
                completion(last, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    private func pruneHistoryIfNeeded(before date: Date?) {
        guard let beforeDate = date else { return }
        let request = NSPersistentHistoryChangeRequest.deleteHistory(before: beforeDate)
        do {
            try container.viewContext.execute(request)
        } catch {
            print("Failed pruning history: \(error)")
        }
    }
}
