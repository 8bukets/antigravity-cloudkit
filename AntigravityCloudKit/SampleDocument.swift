import UIKit

/// SampleDocument: improved UIDocument subclass that registers as an NSFilePresenter
/// to receive change notifications and provide safer multi-process access.
class SampleDocument: UIDocument, NSFilePresenter {
    var presentedItemURL: URL?
    var presentedItemOperationQueue: OperationQueue = OperationQueue()

    override init(fileURL url: URL) {
        super.init(fileURL: url)
        self.presentedItemURL = url
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }

    override func contents(forType typeName: String) throws -> Any {
        // Return Data for the document contents
        if let data = try? Data(contentsOf: fileURL) {
            return data
        }
        return Data()
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Nothing special here; UIDocument will write/read using contents(forType:)
    }

    // NSFilePresenter hooks
    func presentedItemDidChange() {
        // Called when the file changes on disk. Post notifications or reload UI as needed.
        NotificationCenter.default.post(name: NSNotification.Name("SampleDocumentDidChange"), object: fileURL)
    }
}
