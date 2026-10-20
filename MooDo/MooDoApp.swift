import SwiftUI
import SwiftData

@main
struct MooDoApp: App {
    var body: some Scene {
        WindowGroup("MooDo") {
            ContentView()
        }
        .modelContainer(for: TodoItem.self)
    }
}
