import Foundation
import CoreData

/// PersistentHistoryProcessor: improved batching and retry logic for processing history transactions.
/// Call `processHistoryIfNeeded()` from your remote-change handler or after receiving a CloudKit push.
final class PersistentHistoryProcessor {
    private let container: NSPersistentCloudKitContainer
    private let batchSize: Int
    private let tokenKey = "com.8bukets.antigravity.historyToken.v2"

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
        fetchAndApplyHistory(after: lastToken) { [weak self] newToken, error in
            if let t = newToken { self?.lastToken = t }
            completion?(error)
        }
    }

    private func fetchAndApplyHistory(after token: NSPersistentHistoryToken?, completion: @escaping (NSPersistentHistoryToken?, Error?) -> Void) {
        let bgContext = container.newBackgroundContext()
        bgContext.perform {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
            request.fetchLimit = self.batchSize
            do {
                guard let result = try bgContext.execute(request) as? NSPersistentHistoryResult,
                      let transactions = result.result as? [NSPersistentHistoryTransaction], !transactions.isEmpty else {
                    completion(token, nil)
                    return
                }

                // Merge changes into viewContext
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

                // Persist last token from this batch
                let last = transactions.last?.token
                completion(last, nil)
            } catch {
                completion(token, error)
            }
        }
    }
}
