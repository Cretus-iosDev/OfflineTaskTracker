import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String
    var priorityRawValue: String
    var categoryRawValue: String
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    init(
        title: String,
        taskDescription: String = "",
        priority: TaskPriority = .medium,
        category: TaskCategory = .work,
        dueDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = taskDescription
        self.priorityRawValue = priority.rawValue
        self.categoryRawValue = category.rawValue
        self.dueDate = dueDate
        self.createdAt = .now
        self.updatedAt = .now
        self.completedAt = nil
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue; updatedAt = .now }
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRawValue) ?? .work }
        set { categoryRawValue = newValue.rawValue; updatedAt = .now }
    }

    var isCompleted: Bool { completedAt != nil }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: .now)
    }

    func setCompleted(_ completed: Bool) {
        completedAt = completed ? .now : nil
        updatedAt = .now
    }
}
