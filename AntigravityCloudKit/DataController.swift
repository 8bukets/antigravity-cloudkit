import Foundation
import CloudKit
import CoreData
import UIKit

final class DataController {
    static let shared = DataController()
    let container: NSPersistentCloudKitContainer

    private let historyTokenKey = "com.8bukets.antigravity.lastHistoryToken"
    private var lastToken: NSPersistentHistoryToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: historyTokenKey) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }
        set {
            guard let token = newValue else {
                UserDefaults.standard.removeObject(forKey: historyTokenKey)
                return
            }
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
                UserDefaults.standard.set(data, forKey: historyTokenKey)
            }
        }
    }

    private init(inMemory: Bool = false) {
        // Programmatic Core Data model (Note entity)
        let model = NSManagedObjectModel()
        let note = NSEntityDescription()
        note.name = "Note"
        note.managedObjectClassName = "Note"

        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = true

        let body = NSAttributeDescription()
        body.name = "body"
        body.attributeType = .stringAttributeType
        body.isOptional = true

        let modified = NSAttributeDescription()
        modified.name = "modified"
        modified.attributeType = .dateAttributeType
        modified.isOptional = true

        note.properties = [title, body, modified]
        model.entities = [note]

        container = NSPersistentCloudKitContainer(name: "Model", managedObjectModel: model)

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store description")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Replace with your CloudKit container identifier
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.8bukets.antigravity")

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleRemoteStoreChange(_:)),
                                               name: .NSPersistentStoreRemoteChange,
                                               object: container.persistentStoreCoordinator)
    }

    @objc private func handleRemoteStoreChange(_ notification: Notification) {
        // Schedule history processing to reconcile remote changes
        processPersistentHistoryIfNeeded()
    }

    // Public entry point to process history (e.g., after receiving a push)
    func processPersistentHistoryIfNeeded() {
        processPersistentHistory(from: lastToken) { [weak self] newToken in
            if let t = newToken {
                self?.lastToken = t
            }
        }
    }

    // Fetch and apply persistent history transactions since the provided token
    private func processPersistentHistory(from token: NSPersistentHistoryToken?, completion: ((NSPersistentHistoryToken?) -> Void)? = nil) {
        let context = container.newBackgroundContext()
        context.perform {
            let fetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
            do {
                let result = try context.execute(fetchRequest) as? NSPersistentHistoryResult
                guard let transactions = result?.result as? [NSPersistentHistoryTransaction], !transactions.isEmpty else {
                    completion?(token)
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
                        if viewContext.hasChanges {
                            try viewContext.save()
                        }
                    } catch {
                        print("Failed saving viewContext: \(error)")
                    }
                }

                // Save last token
                let last = transactions.last?.token
                completion?(last)
            } catch {
                print("History fetch error: \(error)")
                completion?(token)
            }
        }
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }
}
