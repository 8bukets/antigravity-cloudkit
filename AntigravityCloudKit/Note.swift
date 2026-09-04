import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {
    @NSManaged public var title: String?
    @NSManaged public var body: String?
    @NSManaged public var modified: Date?
}
