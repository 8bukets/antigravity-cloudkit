// swiftdata/CloudKitSyncManager.swift
import Foundation
import CloudKit
import SwiftData

/// Hardened CloudKit sync manager for Note <-> CKRecord mapping with batching,
/// cursor handling, subscriptions, robust retry/backoff and basic conflict resolution.
/// This is a practical template — test and adapt for your app's reliability and scale needs.
public final class CloudKitSyncManager {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "Note"
    private let tokenStore: CKTokenStoreProtocol
    private let queue = OperationQueue()

    public init(containerIdentifier: String, tokenStore: CKTokenStoreProtocol) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = self.container.publicCloudDatabase
        self.tokenStore = tokenStore
        self.queue.maxConcurrentOperationCount = 1
    }

    // MARK: - Mapping
    private func record(from note: Note) -> CKRecord {
        let recordID = CKRecord.ID(recordName: note.id.uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["title"] = note.title as NSString
        record["body"] = note.body as NSString
        record["modifiedAt"] = note.modifiedAt as NSDate
        return record
    }

    // Apply CKRecord -> ModelContext (upsert)
    public func apply(record: CKRecord, into context: ModelContext) {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        if let existing: Note = fetchNoteById(id: id, in: context) {
            // merge strategy: last-write-wins by modifiedAt
            let remoteModified = record["modifiedAt"] as? Date ?? Date()
            if remoteModified > existing.modifiedAt {
                existing.title = record["title"] as? String ?? existing.title
                existing.body = record["body"] as? String ?? existing.body
                existing.modifiedAt = remoteModified
            }
        } else {
            let note = Note(id: id,
                            title: record["title"] as? String ?? "",
                            body: record["body"] as? String ?? "",
                            modifiedAt: record["modifiedAt"] as? Date ?? Date())
            context.insert(note)
        }
    }

    // MARK: - Subscriptions (optional push notifications)
    /// Create or update a query subscription so server can push changes. Handle notifications in AppDelegate/SceneDelegate.
    public func ensureSubscription(recordType: String = "Note", subscriptionID: String = "note-changes") {
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true // silent push
        // Customise alert/body if you want visible notifications

        let subscription = CKQuerySubscription(recordType: recordType,
                                               predicate: NSPredicate(value: true),
                                               subscriptionID: subscriptionID,
                                               options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        subscription.notificationInfo = info

        database.save(subscription) { sub, error in
            if let err = error as? CKError {
                if err.code == .serverRejectedRequest {
                    // subscription already exists or server rejected; consider fetching existing
                }
            }
            // ignore other errors here; they will be retried by higher-level logic if needed
        }
    }

    // MARK: - Push (batching + retry)
    /// Push multiple notes in batches. Uses CKModifyRecordsOperation and retries transient errors.
    public func push(notes: [Note], batchSize: Int = 50, completion: @escaping (Result<Void, Error>) -> Void) {
        let groups = notes.chunked(into: batchSize)
        let group = DispatchGroup()
        var firstError: Error?

        for batch in groups {
            group.enter()
            let records = batch.map { record(from: $0) }
            let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            op.savePolicy = .changedKeys
            op.isAtomic = false
            op.queuePriority = .normal

            op.modifyRecordsCompletionBlock = { saved, deleted, error in
                if let error = error as NSError? {
                    // CKError handling
                    if let ck = CKError(_nsError: error) {
                        switch ck.code {
                        case .serviceUnavailable, .requestRateLimited, .networkUnavailable, .networkFailure:
                            // transient — schedule retry with backoff
                            self.retryModify(records: records, attempt: 1) { res in
                                if case .failure(let e) = res { firstError = firstError ?? e }
                                group.leave()
                            }
                            return
                        default:
                            firstError = firstError ?? error
                        }
                    } else {
                        firstError = firstError ?? error
                    }
                }
                group.leave()
            }
            database.add(op)
        }

        group.notify(queue: .main) {
            if let err = firstError { completion(.failure(err)) } else { completion(.success(())) }
        }
    }

    private func retryModify(records: [CKRecord], attempt: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let maxAttempts = 5
        guard attempt <= maxAttempts else { completion(.failure(NSError(domain: "CloudKitSyncManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Max retry attempts reached"]))); return }
        let delay = pow(2.0, Double(attempt)) + Double.random(in: 0..<1.0)
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            op.savePolicy = .changedKeys
            op.modifyRecordsCompletionBlock = { saved, deleted, error in
                if let error = error as NSError? {
                    // determine if retryable
                    if let ck = CKError(_nsError: error) {
                        switch ck.code {
                        case .serviceUnavailable, .requestRateLimited, .networkUnavailable, .networkFailure:
                            self.retryModify(records: records, attempt: attempt + 1, completion: completion)
                            return
                        default:
                            completion(.failure(error))
                            return
                        }
                    }
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
            self.database.add(op)
        }
    }

    // MARK: - Fetch changes (incremental using modifiedAt + cursor paging)
    /// Fetch all records changed since last sync date. Uses paging and saves lastSyncDate on success.
    public func fetchChanges(into modelContainer: ModelContainer, batchSize: Int = 200, completion: @escaping (Result<Void, Error>) -> Void) {
        let lastSync = tokenStore.loadLastSyncDate()
        let predicate: NSPredicate = {
            if let d = lastSync { return NSPredicate(format: "modifiedAt > %@", d as NSDate) }
            return NSPredicate(value: true)
        }()

        var op = CKQueryOperation(query: CKQuery(recordType: recordType, predicate: predicate))
        op.resultsLimit = batchSize

        var maxModified: Date? = lastSync
        var hadError: Error?

        op.recordFetchedBlock = { record in
            DispatchQueue.main.async {
                let ctx = modelContainer.mainContext
                self.apply(record: record, into: ctx)
                try? ctx.save()
                if let rm = record["modifiedAt"] as? Date { maxModified = max(maxModified ?? rm, rm) }
            }
        }

        op.queryCompletionBlock = { cursor, error in
            if let error = error {
                hadError = error
            }
            if let cursor = cursor {
                self.fetchWithCursor(cursor: cursor, modelContainer: modelContainer, batchSize: batchSize) { res in
                    switch res {
                    case .success:
                        if let mm = maxModified { self.tokenStore.saveLastSyncDate(mm) }
                        if let err = hadError { completion(.failure(err)) } else { completion(.success(())) }
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            } else {
                if let mm = maxModified { self.tokenStore.saveLastSyncDate(mm) }
                if let err = hadError { completion(.failure(err)) } else { completion(.success(())) }
            }
        }

        database.add(op)
    }

    private func fetchWithCursor(cursor: CKQueryOperation.Cursor, modelContainer: ModelContainer, batchSize: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        var op = CKQueryOperation(cursor: cursor)
        op.resultsLimit = batchSize

        var maxModified: Date?
        var hadError: Error?

        op.recordFetchedBlock = { record in
            DispatchQueue.main.async {
                let ctx = modelContainer.mainContext
                self.apply(record: record, into: ctx)
                try? ctx.save()
                if let rm = record["modifiedAt"] as? Date { maxModified = max(maxModified ?? rm, rm) }
            }
        }

        op.queryCompletionBlock = { nextCursor, error in
            if let error = error { hadError = error }
            if let next = nextCursor {
                self.fetchWithCursor(cursor: next, modelContainer: modelContainer, batchSize: batchSize, completion: completion)
            } else {
                if let mm = maxModified { self.tokenStore.saveLastSyncDate(mm) }
                if let err = hadError { completion(.failure(err)) } else { completion(.success(())) }
            }
        }

        database.add(op)
    }

    // MARK: - Helpers
    private func fetchNoteById(id: UUID, in context: ModelContext) -> Note? {
        let fd = FetchDescriptor<Note>(predicate: NSPredicate(format: "id == %@", id as CVarArg))
        do {
            let results = try context.fetch(fd)
            return results.first
        } catch {
            print("fetchNoteById error:", error)
            return nil
        }
    }
}


// MARK: - Utilities
fileprivate extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var idx = 0
        var result: [[Element]] = []
        while idx < self.count {
            let end = Swift.min(idx + size, self.count)
            result.append(Array(self[idx..<end]))
            idx += size
        }
        return result
    }
}
