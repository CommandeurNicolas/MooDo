import Foundation
import SwiftData


@Model
final class Task {
    var title: String
    var isCompleted: Bool = false
    var creationDate: Date = Date()
    var sortOrder: Int
    
    init(title: String, position: Int) {
        self.title = title
        self.sortOrder = position
    }
}
