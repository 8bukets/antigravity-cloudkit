// swiftdata/CKTokenStore.swift
import Foundation
import CloudKit

public final class FileCKTokenStore: CKTokenStoreProtocol {
    let url: URL
    public init(url: URL) { self.url = url }

    public func loadToken() -> CKServerChangeToken? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }

    public func saveToken(_ token: CKServerChangeToken) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
        } catch {
            print("Failed to save CKServerChangeToken:", error)
        }
    }
}
