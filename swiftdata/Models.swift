// swiftdata/Models.swift
import Foundation
import SwiftData

@Model
final class Project: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    @Relationship var notes: [Note]

    init(id: UUID = .init(), title: String, createdAt: Date = .init()) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.notes = []
    }
}

@Model
final class Note: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var modifiedAt: Date
    @Relationship var project: Project?

    init(id: UUID = .init(), title: String, body: String, modifiedAt: Date = .init()) {
        self.id = id
        self.title = title
        self.body = body
        self.modifiedAt = modifiedAt
    }
}
