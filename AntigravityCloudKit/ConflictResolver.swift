import Foundation
import CoreData

/// ConflictResolver: example helpers for resolving Core Data merge conflicts.
/// Use these helpers when you need application-specific merge rules beyond
/// NSMergeByPropertyObjectTrumpMergePolicy.
final class ConflictResolver {
    /// Resolve conflicts for a managed object by preferring the newest modification date.
    /// - Parameters:
    ///   - local: the local NSManagedObject (in viewContext)
    ///   - server: a dictionary of server-side values (from CKRecord or history transaction)
    ///   - dateKey: the key that indicates modification date (e.g., "modified")
    static func preferNewest(local: NSManagedObject, server: [String: Any], dateKey: String = "modified") {
        let localDate = local.value(forKey: dateKey) as? Date
        let serverDate = server[dateKey] as? Date

        if let serverDate = serverDate, let localDate = localDate {
            if serverDate > localDate {
                // Apply server values
                apply(server: server, to: local)
            } else {
                // Keep local values (no-op)
            }
        } else if serverDate != nil {
            apply(server: server, to: local)
        }
    }

    /// Apply server dictionary values to a managed object (simple mapping).
    private static func apply(server: [String: Any], to object: NSManagedObject) {
        server.forEach { key, value in
            if object.entity.attributesByName.keys.contains(key) {
                object.setValue(value is NSNull ? nil : value, forKey: key)
            }
        }
        // Note: call save on context after resolving a batch of conflicts
    }
}
