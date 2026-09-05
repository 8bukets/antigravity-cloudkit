// swiftdata/CloudKitSyncManager.swift
import Foundation
import CloudKit
import SwiftData

/// Basic CloudKit sync manager for simple Note <-> CKRecord mapping.
/// This is a starting point — adapt batching, error handling, retries, and subscriptions.
public final class CloudKitSyncManager {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "Note"
    private let changeTokenStore: CKTokenStoreProtocol

    public init(containerIdentifier: String, tokenStore: CKTokenStoreProtocol) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = self.container.publicCloudDatabase
        self.changeTokenStore = tokenStore
    }

    // Map Note -> CKRecord
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
        // This is pseudocode: fetch by predicate is not direct API in ModelContext; use Query APIs in concrete code
        // For demonstration, assume helper fetchByID exists.
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

    // Push a single note
    public func push(note: Note, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let record = record(from: note)
        let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        op.savePolicy = .changedKeys
        op.modifyRecordsCompletionBlock = { saved, _, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(saved?.first ?? record))
        }
        database.add(op)
    }

    // Fetch changes (basic, uses CKFetchDatabaseChangesOperation & record zone changes if using zone)
    public func fetchChanges(completion: @escaping (Result<Void, Error>) -> Void) {
        // For public DB with recordType, a simple query-based sync can be used.
        // Production: use CKQuerySubscriptions and server change tokens.
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let op = CKQueryOperation(query: query)
        op.recordFetchedBlock = { record in
            // apply records into ModelContainer main context
            DispatchQueue.main.async {
                if let modelContext = try? ModelContainer(for: [Note.self, Project.self]).mainContext {
                    self.apply(record: record, into: modelContext)
                    try? modelContext.save()
                }
            }
        }
        op.queryCompletionBlock = { cursor, error in
            if let error = error { completion(.failure(error)); return }
            completion(.success(()))
        }
        database.add(op)
    }

    // Helper placeholder to fetch Note by id using ModelContext (replace with real query)
    private func fetchNoteById(id: UUID, in context: ModelContext) -> Note? {
        // Implement using appropriate SwiftData query APIs (pseudo)
        // e.g., context.fetch or @Query equivalents
        return nil
    }
}

public protocol CKTokenStoreProtocol {
    func loadToken() -> CKServerChangeToken?
    func saveToken(_ token: CKServerChangeToken)
}
