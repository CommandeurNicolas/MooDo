import SwiftData

enum Field: Hashable {
    case newTask
    case editTask(PersistentIdentifier)
}
