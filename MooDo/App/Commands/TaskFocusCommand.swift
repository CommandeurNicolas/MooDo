import SwiftUI

private struct FocusNewTaskKey: FocusedValueKey {
    // The focus action callback
    typealias Value = () -> Void
}

extension FocusedValues {
    // Giving the action callback a readable name; allows \.focusNewTask
    var focusNewTask: (() -> Void)? {
        get { self[FocusNewTaskKey.self] }
        set { self[FocusNewTaskKey.self] = newValue }
    }
}

// Return shortcut
struct TaskFocusCommand: Commands {
    // Reads the action published by the active scene
    @FocusedValue(\.focusNewTask) private var focusNewTask
    
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Focus new task") {
                // Execute the action
                focusNewTask?()
            }
            // Reacts to return key
            .keyboardShortcut(.return, modifiers: [])
            .disabled(focusNewTask == nil)
        }
    }
}
