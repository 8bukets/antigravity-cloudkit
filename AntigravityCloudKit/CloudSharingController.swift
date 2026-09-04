import SwiftUI
import CloudKit
import UIKit

/// SwiftUI wrapper to present UICloudSharingController for a CKShare
struct CloudSharingController: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer = CKContainer(identifier: "iCloud.com.8bukets.antigravity") // TODO: replace

    func makeUIViewController(context: Context) -> UINavigationController {
        let root = UIViewController()
        root.view.backgroundColor = .systemBackground
        let nav = UINavigationController(rootViewController: root)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Present the sharing controller when share is set
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        uiViewController.present(controller, animated: true)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? { "Shared Item" }
    }
}
