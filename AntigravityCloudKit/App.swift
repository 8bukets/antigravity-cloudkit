import SwiftUI
import CoreData

@main
struct AntigravityCloudKitApp: App {
    let dataController = DataController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\._managedObjectContext, dataController.container.viewContext)
        }
    }
}
