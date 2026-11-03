import Foundation
import SwiftData


@Model
final class TodoItem {
    var title: String
    var isCompleted: Bool = false
    var creationDate: Date = Date()
    
    init(title: String) {
        self.title = title
    }
}
