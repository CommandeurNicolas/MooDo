import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Items list
    @Query private var tasks: [Task]
    private var sortedTasks: [Task] {
        tasks.sorted { first, second in
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            
            return first.sortOrder < second.sortOrder
        }
    }
    
    // TextField focus
    @FocusState private var focusedField: TaskFocusField?
    
    // New task
    private let minListRowHeight: CGFloat = 48
    @State private var newTaskTitle: String = ""

    private var focusNewTaskAction: (() -> Void)? {
        guard focusedField == nil,
              editTaskId == nil,
              !isShowingSaveError
        else { return nil }
        
        return {
            focusedField = .newTask
        }
    }
    
    // Save error handling
    @State private var isShowingSaveError: Bool = false
    @State private var saveErrorMessage: String = ""
    
    // Hover task
    @State private var hoveredTaskId: PersistentIdentifier?
    
    // Edit task
    @State private var editTaskId: PersistentIdentifier?
    @State private var editTaskTitle: String = ""
    @State private var editTaskToRefocus: PersistentIdentifier?

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
                Text("\(tasks.filter { !$0.isCompleted }.count) left")
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .foregroundStyle(.pastureMuted)
            }
            .padding(.bottom, 8)
            
            // Items list
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    List {
                        ForEach(sortedTasks) { task in
                            TaskRowView(
                                task: task,
                                editTaskId: $editTaskId,
                                editTaskTitle: $editTaskTitle,
                                hoveredTaskId: $hoveredTaskId,
                                focusedField: $focusedField,
                                onSave: { updateTaskTitle(task) },
                                onCancel: { resetEditTextField() },
                                onDelete: { deleteItem(task) },
                                onCompletionChange: { saveChanges() }
                            )
                            .id(task.persistentModelID)
                        }
                        .onMove(perform: moveTask)
                    }
                    .environment(\.defaultMinListRowHeight, minListRowHeight) // top = 8, row = 32, bottom = 8
                    .contentMargins(.all, 0, for: .scrollContent)
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    // Place the grip icon in the outer gutter to preserve the checkbox's original alignment.
                    .padding(.leading, -TaskRowView.dragHandleGutterWidth)
                    .onChange(of: tasks.count) { previousCount, newCount in
                        guard newCount > previousCount,
                              let newTask = sortedTasks.last(where: {
                                  !$0.isCompleted
                              })
                        else { return }
                        
                        // Scroll to new task + bottom margin showing the completed task below
                        let peekHeight = minListRowHeight / 2
                        let listHeight = geometry.size.height
                        let hasCompletedTasks = tasks.contains {
                            $0.isCompleted
                        }
                        
                        // Bottom of new task
                        var anchor = UnitPoint.bottom
                        
                        // Update anchor to half of first completed task height
                        if hasCompletedTasks, listHeight > minListRowHeight + peekHeight {
                            anchor = UnitPoint(
                                x: 0.5,
                                y: 1 - peekHeight / (listHeight - minListRowHeight)
                            )
                        }
                        
                        // Scroll to new task
                        withAnimation {
                            proxy.scrollTo(
                                newTask.persistentModelID,
                                anchor: anchor
                            )
                        }
                    }
                }
            }
            

            // New task text field
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
                    text: $newTaskTitle,
                    prompt: Text("What needs doing?")
                        .font(.system(size: 14))
                        .foregroundStyle(.pastureMuted)
                )
                .textFieldStyle(.plain)
                .foregroundStyle(.pastureText)
                .focused(
                    $focusedField,
                    equals: .newTask
                )
                // Submit new task
                .onSubmit {
                    onSubmit()
                }
                .onExitCommand {
                    focusedField = nil
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
                    .opacity(focusedField == .newTask ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .padding(.top, 24) // Margin between list and textfield
            
            // Footer
            HStack(spacing: 7) {
                Circle()
                    .fill(.pastureGreen)
                    .opacity(0.7)
                    .frame(width: 5, height: 5)
                    .accessibilityHidden(true)

                Text("One thing at a time.")
                    .font(.system(size: 11))
                    .foregroundStyle(.pastureMuted)
            }
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
        // Focus
        .focusedSceneValue(\.focusNewTask, focusNewTaskAction)
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
        .onChange(of: isShowingSaveError) { _, isPresented in
            // Refocus edit textfield after alert is dismissed
            guard !isPresented else { return }
            
            let taskID = editTaskToRefocus
            editTaskToRefocus = nil
            
            guard let taskID,
                  editTaskId == taskID
            else { return }
            
            focusedField = .editTask(taskID)
        }
    }
    
    private func getHighestSortOrder() -> Int {
        tasks.map(\.sortOrder).max() ?? -1
    }
    
    private func onSubmit() {
        let title = newTaskTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prevent empty new task
        guard !title.isEmpty else { return }
        
        let newTask = Task(
            title: title,
            position: getHighestSortOrder() + 1
        )
        
        withAnimation {
            modelContext.insert(newTask)
        }
        
        // Try saving
        if saveChanges() {
            newTaskTitle = ""
        } else {
            withAnimation {
                modelContext.delete(newTask)
            }
        }
    }

    private func resetEditTextField() {
        if let editTaskId,
           focusedField == .editTask(editTaskId) {
            // Clear focus
            focusedField = nil
        }
        
        editTaskId = nil
        editTaskTitle = ""
    }
    
    private func updateTaskTitle(_ task: Task) {
        let title = editTaskTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prevent new task with empty title
        guard !title.isEmpty else { return }
        
        // Save previous title for restoration if saving fails
        let previousTitle = task.title
        
        // Edits model in memory
        task.title = title
        
        // Try saving
        if saveChanges() {
            resetEditTextField()
        } else {
            // Restore previous title in memory
            task.title = previousTitle
            // Refocus edit textfield after alert is dismissed
            editTaskToRefocus = task.persistentModelID
        }
    }

    private func deleteItem(_ task: Task) {
        withAnimation {
            modelContext.delete(task)
        }
        // Try saving + reset edit text field in case the user deletes the task while editing
        // TODO: handle differently when moving edit text field to .sheet()
        if saveChanges() && editTaskId == task.persistentModelID {
            resetEditTextField()
        }
    }
    
    private func moveTask(source: IndexSet, destination: Int) {
        guard editTaskId == nil,
              let firstIndex = source.first
        else { return }
        
        let original = sortedTasks
        let isCompleted = original[firstIndex].isCompleted
        let boundary = original.firstIndex(where: {
            $0.isCompleted
        }) ?? original.count
        
        let allowedDestination = isCompleted
            ? boundary...original.count
            : 0...boundary
        
        // Only move tasks within the same completion group
        guard allowedDestination.contains(destination),
              source.allSatisfy({
                  original[$0].isCompleted == isCompleted
              })
        else { return }
        
        var reordered = original
        reordered.move(fromOffsets: source, toOffset: destination)
        
        let groupBefore = original.filter {
            $0.isCompleted == isCompleted
        }
        let groupAfter = reordered.filter {
            $0.isCompleted == isCompleted
        }
        let previousOrders = groupBefore.map(\.sortOrder)
        
        // Reuse this group's positions; leave the other group untouched
        for (task, position) in zip(groupAfter, previousOrders) {
            task.sortOrder = position
        }
        
        if !saveChanges() {
            for (task, position) in zip(groupBefore, previousOrders) {
                task.sortOrder = position
            }
        }
    }
    
    @discardableResult
    private func saveChanges() -> Bool {
        guard modelContext.hasChanges else { return true }
        
        do {
            try modelContext.save()
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            isShowingSaveError = true
            return false
        }
    }
}

#Preview {
    TaskListView()
        .modelContainer(for: Task.self, inMemory: true)
}
