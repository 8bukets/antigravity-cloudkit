import Foundation
import CoreData

/// CKShareMapping: helper to map an NSManagedObject to a persistent CKRecord.RecordName stored on the object.
/// This is a conservative, placeholder-first approach: it writes a UUID string into a `ck_recordName` attribute
/// on the managed object (create the attribute in your model or migrate), and saves the context.
public enum CKShareMapping {
    /// Ensure the object has a stable CKRecord.recordName. If none exists, generate one and persist it.
    /// - Parameters:
    ///   - object: the NSManagedObject (e.g., Note)
    ///   - recordNameKey: attribute name to store the recordName (default: "ck_recordName")
    /// - Returns: the CK recordName string
    @discardableResult
    public static func ensureRecordName(for object: NSManagedObject, recordNameKey: String = "ck_recordName") throws -> String {
        if let existing = object.value(forKey: recordNameKey) as? String, !existing.isEmpty {
            return existing
        }

        // Generate a new stable record name. Using a UUID is safe and avoids collisions.
        let newRecordName = UUID().uuidString
        object.setValue(newRecordName, forKey: recordNameKey)

        // Persist the change on the object's context. Caller should handle errors and merges as appropriate.
        if let context = object.managedObjectContext {
            if context.hasChanges {
                try context.save()
            }
        }

        return newRecordName
    }
}
