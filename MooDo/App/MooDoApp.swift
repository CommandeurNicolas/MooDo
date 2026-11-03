import SwiftUI
import SwiftData

@main
struct MooDoApp: App {
    var body: some Scene {
        WindowGroup("MooDo") {
            TaskListView()
                .frame(idealWidth: 500, idealHeight: 560)
        }
        .defaultSize(width: 500, height: 560)
        .windowIdealSize(.fitToContent)
        .modelContainer(for: Task.self)
        .commands {
            TaskFocusCommand()
        }
    }
}
