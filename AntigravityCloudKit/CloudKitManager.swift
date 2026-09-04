import Foundation
import CloudKit

final class CloudKitManager {
    static let shared = CloudKitManager()
    private let container: CKContainer
    private let privateDB: CKDatabase

    private init(containerIdentifier: String = "iCloud.com.8bukets.antigravity") {
        container = CKContainer(identifier: containerIdentifier)
        privateDB = container.privateCloudDatabase
    }

    func checkAccountStatus(_ completion: @escaping (CKAccountStatus, Error?) -> Void) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                completion(status, error)
            }
        }
    }

    // Ensure a simple subscription exists for Note record changes to receive silent pushes
    func ensureNoteSubscription(completion: ((Error?) -> Void)? = nil) {
        let subscriptionID = "note-changes-subscription"

        privateDB.fetch(withSubscriptionID: subscriptionID) { [weak self] existing, error in
            if existing != nil {
                completion?(nil)
                return
            }

            let predicate = NSPredicate(value: true)
            let subscription = CKQuerySubscription(recordType: "Note",
                                                   predicate: predicate,
                                                   subscriptionID: subscriptionID,
                                                   options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true // silent push
            subscription.notificationInfo = info

            self?.privateDB.save(subscription) { sub, err in
                DispatchQueue.main.async {
                    completion?(err)
                }
            }
        }
    }

    // Handle incoming remote notification and return whether it was CloudKit
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any], completion: @escaping (Bool) -> Void) {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if notification != nil {
            // A CloudKit notification arrived; let higher-level code process history
            completion(true)
        } else {
            completion(false)
        }
    }
}
