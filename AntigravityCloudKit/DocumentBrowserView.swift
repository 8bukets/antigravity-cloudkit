import SwiftUI
import UIKit

/// Simple UIDocument-based UI for iCloud Drive (placeholder example)
struct DocumentBrowserView: View {
    @State private var documents: [URL] = []
    @State private var statusMessage: String = ""

    var body: some View {
        VStack {
            Text("iCloud Documents")
                .font(.headline)
            List(documents, id: \.self) { url in
                Text(url.lastPathComponent)
            }
            HStack {
                Button("Refresh") { loadDocuments() }
                Button("Create Sample") { createSampleDocument() }
            }
            Text(statusMessage)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear(perform: loadDocuments)
    }

    private func ubiquityURL() -> URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }

    private func loadDocuments() {
        guard let docs = ubiquityURL() else {
            statusMessage = "iCloud not available or ubiquity container is nil"
            documents = []
            return
        }

        do {
            let items = try FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)
            documents = items
            statusMessage = "Loaded \(items.count) documents"
        } catch {
            statusMessage = "Error loading documents: \(error)"
            documents = []
        }
    }

    private func createSampleDocument() {
        guard let docs = ubiquityURL() else {
            statusMessage = "iCloud not available"
            return
        }
        let sampleURL = docs.appendingPathComponent("sample_\(UUID().uuidString).txt")
        let text = "Sample document created at \(Date())"
        do {
            try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
            try text.write(to: sampleURL, atomically: true, encoding: .utf8)
            statusMessage = "Created sample document"
            loadDocuments()
        } catch {
            statusMessage = "Failed to create document: \(error)"
        }
    }
}
