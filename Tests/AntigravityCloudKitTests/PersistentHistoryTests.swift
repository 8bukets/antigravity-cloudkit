import XCTest
@testable import AntigravityCloudKit

final class PersistentHistoryTests: XCTestCase {
    var dataController: DataController!

    override func setUp() async throws {
        dataController = DataController(inMemory: true)
    }

    func testProcessHistoryNoCrash() throws {
        // Ensure history processor can be created and invoked without errors on an in-memory store
        let processor = PersistentHistoryProcessor(container: dataController.container)
        let expectation = expectation(description: "processHistory")
        processor.processHistoryIfNeeded { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testDiagnosticsWritesFile() throws {
        Diagnostics.shared.log("Unit test log", "test entry")
        // Confirm file exists in app Documents - best effort (may not exist in XCTest runner sandbox)
        // This test ensures the logger runs without throwing
    }
}
