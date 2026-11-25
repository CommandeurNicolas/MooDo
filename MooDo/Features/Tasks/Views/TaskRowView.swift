import SwiftUI
import SwiftData

struct TaskRowView: View {
    // Grip width plus the gap before the checkbox.
    static let dragHandleGutterWidth: CGFloat = 14 + 8

    @Bindable var task: Task
    
    @Binding var editTaskId: PersistentIdentifier?
    @Binding var editTaskTitle: String
    @Binding var hoveredTaskId: PersistentIdentifier?
    
    var focusedField: FocusState<TaskFocusField?>.Binding
    
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
        HStack(spacing: 8) {
            if isEditing {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 17))
                        .frame(width: 17, height: 17)
                        .foregroundStyle(.pastureGreen)
                        .accessibilityHidden(true)

                    TextField(
                        "edit_task_placeholder",
                        text: $editTaskTitle,
                        prompt: Text("What needs doing?")
                            .foregroundStyle(.pastureMuted)
                    )
                    .font(.system(size: 14))
                    .textFieldStyle(.plain)
                    .foregroundStyle(.pastureText)
                    .focused(
                        focusedField,
                        equals: .editTask(task.persistentModelID)
                    )
                    .onSubmit {
                        onSave()
                    }
                    .onExitCommand {
                        onCancel()
                    }
                }
                .padding(.horizontal, 10)
                .frame(minHeight: 36)
                .background(
                    .pastureField,
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(.pastureBorder, lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(.pastureGreen, lineWidth: 2)
                        .padding(-4)
                        .opacity(
                            focusedField.wrappedValue == .editTask(task.persistentModelID)
                                ? 1 : 0
                        )
                        .allowsHitTesting(false)
                }
                // Leave room for the focus ring before the external Save button.
                .padding(.trailing, 4)
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
            if !isEditing {
                Spacer()
            }
            
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
                    isEditing ? Color.pastureChecked : Color.pastureBackground,
                    in: RoundedRectangle(cornerRadius: 5)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            isEditing ? Color.pastureChecked : Color.pastureBorder,
                            lineWidth: 1
                        )
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(isEditing ? Color.pastureGreen : Color.pastureMuted)
            .opacity(showEditButton ? 1.0 : 0.0)
            .opacity(isEditing && !canSave ? 0.4 : 1)
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
                .font(.system(size: isEditing ? 12 : 15, weight: .regular))
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
        .frame(maxWidth: .infinity, minHeight: isEditing ? 48 : nil)
        .contentShape(Rectangle())
    }
}
