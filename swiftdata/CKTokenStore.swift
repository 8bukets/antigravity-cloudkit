// swiftdata/CKTokenStore.swift
import Foundation
import CloudKit

public protocol CKTokenStoreProtocol {
    func loadToken() -> CKServerChangeToken?
    func saveToken(_ token: CKServerChangeToken)
    func loadLastSyncDate() -> Date?
    func saveLastSyncDate(_ date: Date)
}

public final class FileCKTokenStore: CKTokenStoreProtocol {
    let tokenURL: URL
    let dateURL: URL

    public init(tokenURL: URL, dateURL: URL) {
        self.tokenURL = tokenURL
        self.dateURL = dateURL
    }

    public convenience init(url: URL) {
        let tokenURL = url.appendingPathComponent("ck_change_token.data")
        let dateURL = url.appendingPathComponent("ck_last_sync_date.data")
        self.init(tokenURL: tokenURL, dateURL: dateURL)
    }

    public func loadToken() -> CKServerChangeToken? {
        guard let data = try? Data(contentsOf: tokenURL) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }

    public func saveToken(_ token: CKServerChangeToken) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            try FileManager.default.createDirectory(at: tokenURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: tokenURL)
        } catch {
            print("Failed to save CKServerChangeToken:", error)
        }
    }

    public func loadLastSyncDate() -> Date? {
        guard let data = try? Data(contentsOf: dateURL) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSDate.self, from: data) as Date?
    }

    public func saveLastSyncDate(_ date: Date) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: date as NSDate, requiringSecureCoding: true)
            try FileManager.default.createDirectory(at: dateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: dateURL)
        } catch {
            print("Failed to save lastSyncDate:", error)
        }
    }
}
