import XCTest
@testable import AntigravityCloudKit

final class CKShareMappingTests: XCTestCase {
    var dataController: DataController!

    override func setUp() async throws {
        dataController = DataController(inMemory: true)
    }

    func testEnsureRecordNameCreatesAndPersists() throws {
        let ctx = dataController.container.viewContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Note", into: ctx)
        XCTAssertNil(entity.value(forKey: "ck_recordName"))
        let recordName = try CKShareMapping.ensureRecordName(for: entity)
        XCTAssertFalse(recordName.isEmpty)
        // Confirm persisted
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Note")
        let results = try ctx.fetch(fetch)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.value(forKey: "ck_recordName") as? String, recordName)
    }
}
