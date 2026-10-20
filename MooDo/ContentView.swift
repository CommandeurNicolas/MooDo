import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Items list
    @Query private var items: [TodoItem]
    private var sortedItems: [TodoItem] {
        items.sorted { first, second in
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            
            return first.creationDate < second.creationDate
        }
    }
    
    // New item
    @State private var newItemTitle: String = ""
    
    // Save error handling
    @State private var isShowingSaveError: Bool = false
    @State private var saveErrorMessage: String = ""

    var body: some View {
        VStack {
            // Header
            HStack {
                VStack {
                    Text("A little less to do".uppercased())
                    Text("MooDo.")
                }
                
                // TODO: replace by cow head image
                Text("🐮")
            }
            
            // List count
            HStack {
                Text("My list")
                Text("\(items.filter { !$0.isCompleted }.count) left")
            }
            
            // Items list
            List {
                ForEach(sortedItems) { item in
                    @Bindable var item = item
                    
                    HStack {
                        // Complete item
                        Toggle(
                            "Item \(item.title)",
                            isOn: $item.isCompleted
                        )
                        .toggleStyle(.checkbox)
                        .onChange(of: item.isCompleted) {
                            saveChanges()
                        }
                        .padding()
                        
                        // Delete item
                        Button {
                            deleteItem(item)
                        } label: {
                            Label("Delete \(item.title)", systemImage: "xmark")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                    }
                    
                }
            }

            // New item text field
            TextField(
                "new_item_placeholder",
                text: $newItemTitle,
                prompt: Text("What needs doing?")
            )
            .onSubmit {
                onSubmit()
            }
            
            // Footer
            Text("• One thing at a time.")
        }
        // Save error dialog
        .alert(
            "Couldn't save your changes",
            isPresented: $isShowingSaveError,
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text("Your latest changes haven't been saved.\n\n\(saveErrorMessage)")
            }
        )
    }
    
    private func onSubmit() {
        let title = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prevent empty new item
        guard !title.isEmpty else { return }
        
        withAnimation {
            let newItem = TodoItem(title: title)
            modelContext.insert(newItem)
            newItemTitle = ""
        }
        // Try saving
        saveChanges()
    }

    private func deleteItem(_ item: TodoItem) {
        withAnimation {
            modelContext.delete(item)
        }
        // Try saving
        saveChanges()
    }
    
    private func saveChanges() {
        guard modelContext.hasChanges else { return }
        
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
            isShowingSaveError = true
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
