import Foundation
import CloudKit
import CoreData

final class DataController {
    static let shared = DataController()
    let container: NSPersistentCloudKitContainer

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
        // Process persistent history or merge UI updates as needed
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }
}
