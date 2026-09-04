import Foundation
import CloudKit
import CoreData
import UIKit

/// ShareFlow: higher-level placeholder flow to share a Note (Core Data object) via CKShare.
/// This is a placeholder-first implementation: it shows the steps you must implement to map
/// a Core Data object to its CKRecord.ID and create a CKShare. You must replace TODOs
/// with your app-specific mapping code.
final class ShareFlow {
    static let shared = ShareFlow()
    private let container = CKContainer(identifier: "iCloud.com.8bukets.antigravity") // TODO: replace
    private let privateDB: CKDatabase

    private init() {
        privateDB = container.privateCloudDatabase
    }

    /// High-level: share a Note object.
    /// - Parameters:
    ///   - note: the NSManagedObject you want to share
    ///   - presentingViewController: view controller to present the UICloudSharingController
    ///   - completion: returns the CKShare or an error
    func share(note: Note, presentingViewController: UIViewController, completion: @escaping (CKShare?, Error?) -> Void) {
        // 1) Obtain the CKRecord.ID for this Note. With NSPersistentCloudKitContainer, Core Data maps
        //    objects to CKRecords in the private DB. Your app must store or derive the CKRecord.ID
        //    for a given NSManagedObject. This placeholder attempts to fetch the record via a known
        //    recordName stored in a "ck_recordName" attribute — replace with your mapping.

        guard let recordName = note.value(forKey: "ck_recordName") as? String else {
            completion(nil, NSError(domain: "ShareFlow", code: 1, userInfo: [NSLocalizedDescriptionKey: "No ck_recordName mapping found on Note. Implement mapping from NSManagedObject to CKRecord.ID."]))
            return
        }

        let recordID = CKRecord.ID(recordName: recordName)

        // 2) Fetch the record to use as the root of the share
        privateDB.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            guard let root = record else {
                DispatchQueue.main.async { completion(nil, NSError(domain: "ShareFlow", code: 2, userInfo: [NSLocalizedDescriptionKey: "Root record not found"])) }
                return
            }

            // 3) Create a CKShare for the root record
            let share = CKShare(rootRecord: root)
            share[CKShare.SystemFieldKey.title] = (note.title ?? "Shared Note") as CKRecordValue

            let modifyOp = CKModifyRecordsOperation(recordsToSave: [root, share], recordIDsToDelete: nil)
            modifyOp.savePolicy = .allKeys
            modifyOp.modifyRecordsCompletionBlock = { saved, deleted, opError in
                DispatchQueue.main.async {
                    if let opError = opError {
                        completion(nil, opError)
                        return
                    }

                    // Present the UICloudSharingController for the created share
                    if let savedShare = saved?.compactMap({ $0 as? CKShare }).first {
                        let controller = UICloudSharingController(share: savedShare, container: self.container)
                        controller.delegate = presentingViewController as? UICloudSharingControllerDelegate
                        presentingViewController.present(controller, animated: true) {
                            completion(savedShare, nil)
                        }
                    } else {
                        completion(nil, NSError(domain: "ShareFlow", code: 3, userInfo: [NSLocalizedDescriptionKey: "Share not found in saved records"]))
                    }
                }
            }

            self.privateDB.add(modifyOp)
        }
    }
}
