import XCTest
@testable import AntigravityCloudKit

final class IntegrationTests: XCTestCase {
    var dataController: DataController!

    override func setUp() async throws {
        dataController = DataController(inMemory: true)
    }

    func testCreateAndReadSampleDocument() throws {
        // Use the ubiquity container if available - this test runs in simulator context on CI
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("No document directory available")
            return
        }

        let url = docs.appendingPathComponent("integration_sample_\(UUID().uuidString).txt")
        let text = "Integration test document at \(Date())"

        let expectationWrite = expectation(description: "write")
        DocumentCoordinator.shared.writeText(text, to: url) { error in
            XCTAssertNil(error)
            expectationWrite.fulfill()
        }
        waitForExpectations(timeout: 5)

        let expectationRead = expectation(description: "read")
        DocumentCoordinator.shared.readText(from: url) { read, error in
            XCTAssertNil(error)
            XCTAssertEqual(read, text)
            expectationRead.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}
