import Foundation

/// Diagnostics: lightweight logger for CloudKit/Core Data operations.
/// Writes messages to Console and optionally to a file in the app's documents directory.
final class Diagnostics {
    static let shared = Diagnostics()
    private init() {}

    private var fileURL: URL? {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent("antigravity_logs.txt")
    }

    func log(_ message: String, _ items: Any?...) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let body = items.compactMap { $0 }.map { "\($0)" }.joined(separator: " ")
        let line = "[\(timestamp)] \(message) \(body)\n"
        print(line)
        if let url = fileURL {
            if let data = line.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: url.path) {
                    if let fh = try? FileHandle(forWritingTo: url) {
                        fh.seekToEndOfFile()
                        fh.write(data)
                        fh.closeFile()
                    }
                } else {
                    try? data.write(to: url)
                }
            }
        }
    }
}
