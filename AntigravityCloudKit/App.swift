import SwiftUI
import CoreData

@main
struct AntigravityCloudKitApp: App {
    // App delegate to handle push notifications and CloudKit callbacks
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let dataController = DataController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\._managedObjectContext, dataController.container.viewContext)
        }
    }
}
