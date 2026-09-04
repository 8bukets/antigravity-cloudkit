import XCTest
@testable import AntigravityCloudKit
import CoreData

final class AntigravityCloudKitTests: XCTestCase {
    var dataController: DataController!

    override func setUp() async throws {
        dataController = DataController(inMemory: true)
    }

    func testCreateNote() throws {
        let context = dataController.container.viewContext
        let note = Note(context: context)
        note.title = "Test"
        note.body = "Body"
        note.modified = Date()
        try context.save()

        let fetch = NSFetchRequest<Note>(entityName: "Note")
        let results = try context.fetch(fetch)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Test")
    }
}
