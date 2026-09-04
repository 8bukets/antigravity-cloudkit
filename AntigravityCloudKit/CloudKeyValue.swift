import Foundation

final class CloudKeyValue {
    static let shared = CloudKeyValue()
    private let store = NSUbiquitousKeyValueStore.default

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(changed(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
    }

    @objc private func changed(_ note: Notification) {
        // Handle remote changes
    }

    func set(_ value: Any?, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func value(forKey key: String) -> Any? {
        store.object(forKey: key)
    }
}
