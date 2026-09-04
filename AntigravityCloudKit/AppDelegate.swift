import UIKit
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register for remote notifications to receive CloudKit silent pushes
        UIApplication.shared.registerForRemoteNotifications()

        // Optionally check account status and create subscription
        CloudKitManager.shared.checkAccountStatus { status, error in
            switch status {
            case .available:
                CloudKitManager.shared.ensureNoteSubscription()
            default:
                print("iCloud account not available: \(String(describing: error))")
            }
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Device token registered — CloudKit uses APS but you don't need to forward token
        print("Registered for remote notifications: \(deviceToken.count) bytes")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        CloudKitManager.shared.handleRemoteNotification(userInfo) { isCloudKit in
            if isCloudKit {
                // Trigger processing of persistent history to reconcile remote changes
                DataController.shared.processPersistentHistoryIfNeeded()
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }
}
