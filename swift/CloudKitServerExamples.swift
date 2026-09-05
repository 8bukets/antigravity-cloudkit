import Foundation
import CoreData

// TokenStore — serializes NSPersistentHistoryToken to disk
public final class TokenStore {
    let url: URL
    public init(url: URL) { self.url = url }

    public func load() -> NSPersistentHistoryToken? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSPersistentHistoryToken
    }

    public func save(_ token: NSPersistentHistoryToken) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
        } catch {
            print("TokenStore save failed:", error)
        }
    }
}

// Simple PersistentHistoryProcessor skeleton
public final class PersistentHistoryProcessor {
    let container: NSPersistentCloudKitContainer
    let tokenStore: TokenStore

    public init(container: NSPersistentCloudKitContainer, tokenStore: TokenStore) {
        self.container = container
        self.tokenStore = tokenStore
    }

    public func processOnce() {
        let token = tokenStore.load()
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
        let ctx = container.newBackgroundContext()
        ctx.performAndWait {
            do {
                let result = try ctx.execute(request) as? NSPersistentHistoryResult
                guard let transactions = result?.result as? [NSPersistentHistoryTransaction], !transactions.isEmpty else { return }
                for tx in transactions {
                    // process each transaction: tx.changes
                    // map recordIDs / update app state / notify UI
                }
                if let last = transactions.last?.token {
                    tokenStore.save(last)
                }
            } catch {
                print("Failed to fetch history:", error)
            }
        }
    }
}
