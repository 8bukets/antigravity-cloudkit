import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\\.managedObjectContext) private var viewContext
    @FetchRequest(entity: NSManagedObject.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \\Note?.modified, ascending: false)]) private var notes: FetchedResults<Note>

    @State private var newTitle = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(notes, id: \\._objectID) { note in
                    VStack(alignment: .leading) {
                        Text(note.title ?? "Untitled")
                            .font(.headline)
                        Text(note.body ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addNote) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func addNote() {
        let note = Note(context: viewContext)
        note.title = "New note"
        note.body = ""
        note.modified = Date()
        try? viewContext.save()
    }

    private func delete(offsets: IndexSet) {
        offsets.map { notes[$0] }.forEach(viewContext.delete)
        try? viewContext.save()
    }
}
