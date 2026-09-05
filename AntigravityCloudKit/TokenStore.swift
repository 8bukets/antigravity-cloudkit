import Foundation

/// TokenStore: persistence helper for NSPersistentHistoryToken using atomic file storage in Application Support.
/// This avoids relying on UserDefaults and provides a resumable token storage that can be inspected by devs.
final class TokenStore {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.8bukets.antigravity.tokenstore")

    init(subpath: String = "com.8bukets.antigravity.historyToken.v1") {
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport ?? fm.temporaryDirectory
        fileURL = dir.appendingPathComponent(subpath)
    }

    func loadToken() -> NSPersistentHistoryToken? {
        return queue.sync {
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }
    }

    func saveToken(_ token: NSPersistentHistoryToken?) {
        queue.sync {
            guard let token = token else {
                try? FileManager.default.removeItem(at: fileURL)
                return
            }
            if let d = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
                // atomic write
                try? d.write(to: fileURL, options: .atomic)
            }
        }
    }
}
