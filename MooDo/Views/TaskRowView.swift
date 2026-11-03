import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Bindable var task: TodoItem
    
    @Binding var editTaskId: PersistentIdentifier?
    @Binding var editTaskTitle: String
    @Binding var hoveredTaskId: PersistentIdentifier?
    
    var focusedField: FocusState<Field?>.Binding
    
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    let onCompletionChange: () -> Void
    
    private var isEditing: Bool {
        editTaskId == task.persistentModelID
    }
    
    private var showEditButton: Bool {
        isEditing || hoveredTaskId == task.persistentModelID
    }
    
    private var canSave: Bool {
        !editTaskTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
    
    var body: some View {
        HStack {
            if editTaskId == task.persistentModelID {
                // Text field
                TextField(
                    "edit_task_placeholder",
                    text: $editTaskTitle,
                    prompt: Text("What needs doing?")
                        .font(.system(size: 14))
                        .foregroundStyle(.pastureMuted)
                )
                .textFieldStyle(.plain)
                .foregroundStyle(.pastureText)
                .focused(
                    focusedField,
                    equals: .editTask(task.persistentModelID)
                )
                // Edit task
                .onSubmit {
                    // TODO: onEdit function?
                    onSave()
                }
                .onExitCommand {
                    onCancel()
                }
            } else {
                // Complete task
                Toggle(isOn: $task.isCompleted) {
                    Text(task.title)
                        .font(.system(size: 14))
                        .foregroundStyle(
                            task.isCompleted ? .pastureMuted: .pastureText
                        )
                        .strikethrough(
                            task.isCompleted,
                            color: .pastureStrikethrough
                        )
                }
                .toggleStyle(PastureCheckboxStyle())
                .onChange(of: task.isCompleted) {
                    onCompletionChange()
                }
            }
            
            // Some space
            Spacer()
            
            // Edit / Save
            Button {
                if isEditing {
                    onSave()
                } else {
                    editTaskTitle = task.title
                    editTaskId = task.persistentModelID
                    focusedField.wrappedValue = .editTask(task.persistentModelID)
                }
            } label: {
                Label(
                    isEditing ? "Save changes" : "Edit \(task.title)",
                    systemImage: isEditing ? "checkmark" : "pencil"
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 12, weight: .medium))
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
            .foregroundStyle(.pastureMuted)
            .opacity(showEditButton ? 1.0 : 0.0)
            .allowsHitTesting(showEditButton)
            .disabled(isEditing ? !canSave : editTaskId != nil)
            .help(isEditing ? "Save changes" : "Edit task")
            
            // Delete / Cancel
            Button {
                if isEditing {
                    onCancel()
                } else {
                    onDelete()
                }
            } label: {
                Label(
                    isEditing ? "Cancel editing" : "Delete \(task.title)",
                    systemImage: isEditing ? "xmark" : "trash"
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 15, weight: .regular))
                .frame(width: 28, height: 28)
                .if(isEditing) {
                    $0.background(
                        .pastureBackground,
                        in: RoundedRectangle(cornerRadius: 5)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(.pastureBorder, lineWidth: 1)
                    }
                }
                
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.pastureMuted)
            .help(isEditing ? "Cancel editing" : "Delete task")
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowSeparator(.visible, edges: .bottom)
        .listRowSeparatorTint(.pastureBorder, edges: .bottom)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onHover { isHovering in
            if isHovering {
                hoveredTaskId = task.persistentModelID
            } else if hoveredTaskId == task.persistentModelID {
                hoveredTaskId = nil
            }
        }
    }
}

