import Testing
import CoreGraphics
@testable import MooDo

struct MooDoTests {

    private let frames = (0..<5).map {
        CGRect(x: 0, y: $0 * 48, width: 400, height: 48)
    }
    private let completed = [false, false, false, true, true]

    @Test func movesUpAndDownUsingOriginalInsertionOffsets() {
        #expect(target(source: 2, y: 0) == 0)
        #expect(target(source: 0, y: 110) == 2)
        #expect(target(source: 0, y: 140) == 3)
        #expect(target(source: 3, y: 240) == 5)
        #expect(target(source: 4, y: 150) == 3)
    }

    @Test func rejectsDestinationsInAnotherCompletionGroup() {
        #expect(target(source: 0, y: 200) == nil)
        #expect(target(source: 3, y: 0) == nil)
    }

    @Test func returnsNilWhenTaskOrderWouldNotChange() {
        #expect(target(source: 1, y: 50) == nil)
        #expect(target(source: 1, y: 80) == nil)
    }

    @Test func handlesListsWithOnlyOneCompletionGroup() {
        #expect(TaskReorderTarget.destination(at: 240, frames: frames, source: 0, completed: Array(repeating: false, count: 5)) == 5)
        #expect(TaskReorderTarget.destination(at: 0, frames: frames, source: 4, completed: Array(repeating: true, count: 5)) == 0)
    }

    @Test func ignoresMissingGeometryAndInvalidSources() {
        #expect(TaskReorderTarget.destination(at: 0, frames: [], source: 0, completed: completed) == nil)
        #expect(target(source: -1, y: 0) == nil)
        #expect(target(source: 5, y: 0) == nil)
    }

    private func target(source: Int, y: CGFloat) -> Int? {
        TaskReorderTarget.destination(at: y, frames: frames, source: source, completed: completed)
    }

}
