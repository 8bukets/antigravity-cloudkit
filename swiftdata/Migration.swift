// swiftdata/Migration.swift
import Foundation
import CoreData
import SwiftData

/// Skeleton migration tool: Core Data -> SwiftData
/// Use on a copy of production DB. Commit in batches to avoid memory blowup.
public struct CoreDataToSwiftDataMigrator {
    let persistentContainer: NSPersistentContainer
    let modelContainer: ModelContainer

    public init(persistentContainer: NSPersistentContainer, modelContainer: ModelContainer) {
        self.persistentContainer = persistentContainer
        self.modelContainer = modelContainer
    }

    public func migrate(batchSize: Int = 500) throws {
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true

        // Example migrating NoteEntity -> Note
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "NoteEntity")
        fetchRequest.fetchBatchSize = batchSize

        let results = try context.fetch(fetchRequest)
        var processed = 0
        let mainContext = modelContainer.mainContext

        for mo in results {
            autoreleasepool {
                let id = (mo.value(forKey: "id") as? UUID) ?? UUID()
                let title = mo.value(forKey: "title") as? String ?? ""
                let body = mo.value(forKey: "body") as? String ?? ""
                let modifiedAt = mo.value(forKey: "modifiedAt") as? Date ?? Date()

                let note = Note(id: id, title: title, body: body, modifiedAt: modifiedAt)
                mainContext.insert(note)

                processed += 1
                if processed % batchSize == 0 {
                    do {
                        try mainContext.save()
                        // optionally reset container or drain memory
                    } catch {
                        print("Save error during migration:", error)
                    }
                }
            }
        }

        // final save
        try mainContext.save()
    }
}
