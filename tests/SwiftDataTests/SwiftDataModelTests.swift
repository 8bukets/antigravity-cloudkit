// tests/SwiftDataTests/SwiftDataModelTests.swift
import XCTest
import SwiftData

@testable import YourModuleName // adjust target/module name

final class SwiftDataModelTests: XCTestCase {
    var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainer(for: [Note.self, Project.self], inMemory: true)
    }

    func testInsertAndFetchNote() throws {
        let ctx = container.mainContext
        let note = Note(title: "t1", body: "b1")
        ctx.insert(note)
        try ctx.save()

        // Use SwiftData query APIs — this is illustrative pseudocode
        // Replace with real fetch depending on your test helpers
        // e.g., let results: [Note] = try ctx.fetch(...)
        // XCTAssertTrue(results.contains { $0.id == note.id })
    }
}
