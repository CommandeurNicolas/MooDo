import SwiftData

enum TaskFocusField: Hashable {
    case newTask
    case editTask(PersistentIdentifier)
}
