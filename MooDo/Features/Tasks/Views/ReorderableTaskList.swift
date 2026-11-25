import SwiftUI
import SwiftData

/// Keeps the insertion target in the original collection's coordinate system,
/// matching the destination expected by Array.move(fromOffsets:toOffset:).
enum TaskReorderTarget {
    static func destination(
        at y: CGFloat,
        frames: [CGRect],
        source: Int,
        completed: [Bool]
    ) -> Int? {
        guard frames.count == completed.count,
              completed.indices.contains(source)
        else { return nil }

        let destination = frames.firstIndex { y < $0.midY } ?? frames.count
        let boundary = completed.firstIndex(of: true) ?? completed.count
        let allowed = completed[source] ? boundary...completed.count : 0...boundary
        guard allowed.contains(destination),
              destination != source,
              destination != source + 1
        else { return nil }
        return destination
    }
}

struct ReorderableTaskList<Row: View>: View {
    static var handleGutterWidth: CGFloat { TaskRowView.dragHandleGutterWidth }

    let tasks: [Task]
    let isEnabled: Bool
    @Binding var hoveredTaskID: PersistentIdentifier?
    let onMove: (IndexSet, Int) -> Void
    @ViewBuilder let row: (Task) -> Row

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isListFocused: Bool
    @GestureState private var isDragging = false
    @State private var draggedTaskID: PersistentIdentifier?
    @State private var dragLocation: CGPoint?
    @State private var cancelled = false
    @State private var frames: [PersistentIdentifier: CGRect] = [:]
    @State private var scrollPosition = ScrollPosition()
    @State private var scrollMetrics = ScrollMetrics()

    private let coordinateSpace = NamedCoordinateSpace.named("taskReorderList")

    private var destination: Int? {
        guard !cancelled, let dragLocation, let draggedTaskID,
              let source = tasks.firstIndex(where: { $0.persistentModelID == draggedTaskID }),
              tasks.allSatisfy({ frames[$0.persistentModelID] != nil }),
              dragLocation.x >= 0, dragLocation.x <= scrollMetrics.width,
              dragLocation.y >= 0, dragLocation.y <= scrollMetrics.height
        else { return nil }

        return TaskReorderTarget.destination(
            at: dragLocation.y,
            frames: tasks.compactMap { frames[$0.persistentModelID] },
            source: source,
            completed: tasks.map(\.isCompleted)
        )
    }

    private var indicatorY: CGFloat? {
        guard let destination else { return nil }
        if destination < tasks.count {
            return frames[tasks[destination].persistentModelID]?.minY
        }
        return tasks.last.flatMap { frames[$0.persistentModelID]?.maxY }
    }

    private var autoScrollDirection: Int {
        guard draggedTaskID != nil, !cancelled, let dragLocation,
              dragLocation.x >= 0, dragLocation.x <= scrollMetrics.width,
              dragLocation.y >= 0, dragLocation.y <= scrollMetrics.height
        else { return 0 }
        let edge = min(36.0, scrollMetrics.height / 4)
        if dragLocation.y < edge { return -1 }
        if dragLocation.y > scrollMetrics.height - edge { return 1 }
        return 0
    }

    var body: some View {
        ScrollView {
            // Keep the source mounted while edge scrolling during a drag.
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    HStack(spacing: 8) {
                        handle(for: task)
                        row(task)
                            .opacity(draggedTaskID == task.persistentModelID && !cancelled ? 0.45 : 1)
                    }
                    .padding(.vertical, 8)
                    .frame(minHeight: 48)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(.pastureBorder)
                            .frame(height: 1)
                            .padding(.leading, Self.handleGutterWidth)
                            .allowsHitTesting(false)
                    }
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            hoveredTaskID = task.persistentModelID
                        } else if hoveredTaskID == task.persistentModelID {
                            hoveredTaskID = nil
                        }
                    }
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: TaskRowFrames.self,
                                value: [task.persistentModelID: geometry.frame(in: coordinateSpace)]
                            )
                        }
                    }
                    .id(task.persistentModelID)
                    .accessibilityElement(children: .contain)
                    .accessibilityAction(named: "Move up") { move(task, by: -1) }
                    .accessibilityAction(named: "Move down") { move(task, by: 1) }
                }
            }
            .padding(.vertical, 1) // Keep end insertion indicators inside the scroll clip.
        }
        .coordinateSpace(coordinateSpace)
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: ScrollMetrics.self) { geometry in
            ScrollMetrics(
                offset: geometry.contentOffset.y,
                maximumOffset: max(0, geometry.contentSize.height - geometry.containerSize.height),
                width: geometry.containerSize.width,
                height: geometry.containerSize.height
            )
        } action: { _, metrics in
            scrollMetrics = metrics
        }
        .onPreferenceChange(TaskRowFrames.self) { frames = $0 }
        .overlay(alignment: .topLeading) {
            if let indicatorY {
                Capsule()
                    .fill(.pastureGreen)
                    .frame(height: 2)
                    .padding(.leading, Self.handleGutterWidth)
                    .offset(y: indicatorY - 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .clipped()
        .focusable()
        .focusEffectDisabled()
        .focused($isListFocused)
        .onChange(of: isDragging) { _, active in
            if !active { resetDrag() }
        }
        .onChange(of: isEnabled) { _, enabled in
            if !enabled, draggedTaskID != nil { cancelled = true }
        }
        .onChange(of: tasks.map(\.persistentModelID)) { _, _ in
            if draggedTaskID != nil { cancelled = true }
        }
        .onExitCommand {
            if draggedTaskID != nil { cancelled = true }
        }
        .onDisappear { resetDrag() }
        .task(id: autoScrollDirection) {
            let direction = autoScrollDirection
            guard direction != 0 else { return }
            while !_Concurrency.Task<Never, Never>.isCancelled {
                do {
                    try await _Concurrency.Task<Never, Never>.sleep(for: .milliseconds(30))
                } catch { return }
                let offset = min(scrollMetrics.maximumOffset, max(0, scrollMetrics.offset + CGFloat(direction) * 7))
                scrollPosition.scrollTo(y: offset)
            }
        }
    }

    private func handle(for task: Task) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.pastureMuted)
            .frame(width: 14, height: 28)
            .contentShape(Rectangle())
            .pointerStyle(isDragging ? .grabActive : .grabIdle)
            .opacity(isEnabled && (hoveredTaskID == task.persistentModelID || draggedTaskID == task.persistentModelID) ? 1 : 0)
            .allowsHitTesting(isEnabled)
            .help("Drag to reorder")
            .accessibilityHidden(true)
            .gesture(
                DragGesture(minimumDistance: 3, coordinateSpace: coordinateSpace)
                    .updating($isDragging) { _, active, _ in active = true }
                    .onChanged { value in
                        guard isEnabled, !cancelled else { return }
                        if draggedTaskID == nil { isListFocused = true }
                        draggedTaskID = task.persistentModelID
                        dragLocation = value.location
                    }
                    .onEnded { value in
                        dragLocation = value.location
                        if isEnabled, !cancelled, let destination,
                           let source = tasks.firstIndex(where: { $0.persistentModelID == draggedTaskID }) {
                            commit(source: source, destination: destination)
                        }
                        resetDrag()
                    }
            )
    }

    private func move(_ task: Task, by direction: Int) {
        guard isEnabled, draggedTaskID == nil,
              let source = tasks.firstIndex(where: { $0.persistentModelID == task.persistentModelID }),
              tasks.indices.contains(source + direction),
              tasks[source + direction].isCompleted == task.isCompleted
        else { return }
        commit(source: source, destination: direction < 0 ? source - 1 : source + 2)
    }

    private func commit(source: Int, destination: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
            onMove(IndexSet(integer: source), destination)
        }
    }

    private func resetDrag() {
        draggedTaskID = nil
        dragLocation = nil
        cancelled = false
    }
}

private struct ScrollMetrics: Equatable {
    var offset: CGFloat = 0
    var maximumOffset: CGFloat = 0
    var width: CGFloat = 0
    var height: CGFloat = 0
}

private struct TaskRowFrames: PreferenceKey {
    static let defaultValue: [PersistentIdentifier: CGRect] = [:]

    static func reduce(value: inout [PersistentIdentifier: CGRect], nextValue: () -> [PersistentIdentifier: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
