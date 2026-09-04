import Foundation
import UIKit

/// DocumentCoordinator: helper that uses NSFileCoordinator to safely read and write files
/// in the ubiquity container. This improves reliability when multiple processes may access files.
final class DocumentCoordinator {
    static let shared = DocumentCoordinator()

    private init() {}

    func writeText(_ text: String, to url: URL, completion: @escaping (Error?) -> Void) {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var error: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &error) { newURL in
            do {
                try text.write(to: newURL, atomically: true, encoding: .utf8)
                completion(nil)
            } catch {
                completion(error)
            }
        }
        if let e = error { completion(e) }
    }

    func readText(from url: URL, completion: @escaping (String?, Error?) -> Void) {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var error: NSError?
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { newURL in
            do {
                let s = try String(contentsOf: newURL, encoding: .utf8)
                completion(s, nil)
            } catch {
                completion(nil, error)
            }
        }
        if let e = error { completion(nil, e) }
    }
}
