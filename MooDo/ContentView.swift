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
    @FocusState private var isNewTaskFocused: Bool
    @State private var newItemTitle: String = ""
    
    // Save error handling
    @State private var isShowingSaveError: Bool = false
    @State private var saveErrorMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                // Tagline & title
                VStack(alignment: .leading, spacing: 5) {
                    // Tagline
                    Text("A little less to do".uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.7)
                        .foregroundStyle(.pastureMuted)
                    
                    // Title
                    Text("MooDo\(Text(".").foregroundStyle(.pastureGreen))")
                        .font(.system(size: 44, weight: .semibold))
                        .tracking(-2.3)
                        .foregroundStyle(.pastureText)
                }
                
                // Some space
                Spacer()

                // Logo
                Image("CowHead")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 79)
                    .accessibilityHidden(true)
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 31, trailing: 4))
            
            // List count
            HStack {
                Text("My list")
                    .font(.system(size: 14, weight: .semibold))
                Spacer() // Some space
                
                // Not completed tasks count
                Text("\(items.filter { !$0.isCompleted }.count) left")
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .foregroundStyle(.pastureMuted)
            }
            .padding(.bottom, 8)
            
            // Items list
            List {
                ForEach(sortedItems) { item in
                    @Bindable var item = item
                    
                    HStack {
                        // Complete item
                        Toggle(isOn: $item.isCompleted) {
                            Text(item.title)
                                .font(.system(size: 14))
                                .foregroundStyle(
                                    item.isCompleted ? .pastureMuted: .pastureText
                                )
                                .strikethrough(
                                    item.isCompleted,
                                    color: .pastureStrikethrough
                                )
                        }
                        .toggleStyle(PastureCheckboxStyle())
                        .onChange(of: item.isCompleted) {
                            saveChanges()
                        }
                        
                        // Some space
                        Spacer()
                        
                        // Delete item
                        Button {
                            deleteItem(item)
                        } label: {
                            Label("Delete \(item.title)", systemImage: "xmark")
                                .font(.system(size: 15, weight: .regular))
                                .labelStyle(.iconOnly)
                                .frame(width: 30, height: 30)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.pastureMuted)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.visible, edges: .bottom)
                    .listRowSeparatorTint(.pastureBorder, edges: .bottom)
                }
            }
            .environment(\.defaultMinListRowHeight, 48) // top = 8, item = 32, bottom = 8
            .contentMargins(.all, 0, for: .scrollContent)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            // New item text field
            HStack(spacing: 10) {
                // Leading plus icon
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 17, height: 17)
                    .foregroundStyle(.pastureGreen)
                    .accessibilityHidden(true)
                
                // Text field
                TextField(
                    "new_item_placeholder",
                    text: $newItemTitle,
                    prompt: Text("What needs doing?")
                        .font(.system(size: 14))
                        .foregroundStyle(.pastureMuted)
                )
                .textFieldStyle(.plain)
                .foregroundStyle(.pastureText)
                .focused($isNewTaskFocused)
                // Submit new task
                .onSubmit {
                    onSubmit()
                }
                
                // Trailing return icon
                Button {
                    onSubmit()
                } label: {
                    Image(systemName: "return")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.pastureMuted)
                        .frame(width: 28, height: 28)
                        .background(
                            .pastureBackground,
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(.pastureBorder, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add task")
            }
            .padding(EdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 10))
            .background(
                .pastureField,
                in: RoundedRectangle(cornerRadius: 9)
            )
            // Normal border, always visible
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(.pastureBorder, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            // Outer focus ring
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(.pastureGreen, lineWidth: 2)
                    .padding(-4)
                    .opacity(isNewTaskFocused ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .padding(.top, 24) // Margin between list and textfield
            
            // Footer
            Text("\(Text("•").foregroundStyle(.pastureGreen)) One thing at a time.")
                .foregroundStyle(.pastureMuted)
                .font(.system(size: 11))
                .frame(maxWidth: .infinity)
                .padding(.top, 22) // Margin between text field and footer
        }
        .padding(EdgeInsets(top: 30, leading: 30, bottom: 21, trailing: 30))
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .font(.system(size: 14)) // Default text size
        .foregroundStyle(.pastureText)
        .background(.pastureBackground)
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
