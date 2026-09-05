import UIKit

class SampleDocument: UIDocument, NSFilePresenter {
    var presentedItemURL: URL?
    var presentedItemOperationQueue: OperationQueue = OperationQueue()
    private var autosaveTimer: Timer?

    override init(fileURL url: URL) {
        super.init(fileURL: url)
        self.presentedItemURL = url
        NSFileCoordinator.addFilePresenter(self)
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
        autosaveTimer?.invalidate()
    }

    override func open(completionHandler: ((Bool) -> Void)? = nil) {
        super.open { success in
            if success {
                // Start autosave timer
                DispatchQueue.main.async {
                    self.autosaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                        guard let self = self else { return }
                        self.updateChangeCount(.done)
                        self.save(to: self.fileURL, for: .forOverwriting) { _ in }
                    }
                }
            }
            completionHandler?(success)
        }
    }

    override func close(completionHandler: ((Bool) -> Void)? = nil) {
        autosaveTimer?.invalidate()
        super.close(completionHandler: completionHandler)
    }

    override func contents(forType typeName: String) throws -> Any {
        if let data = try? Data(contentsOf: fileURL) {
            return data
        }
        return Data()
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // handle loading if needed
    }

    func presentedItemDidChange() {
        NotificationCenter.default.post(name: NSNotification.Name("SampleDocumentDidChange"), object: fileURL)
    }

    func presentedItemDidMove(to newURL: URL) {
        // update internal URL references
        self.presentedItemURL = newURL
    }
}
