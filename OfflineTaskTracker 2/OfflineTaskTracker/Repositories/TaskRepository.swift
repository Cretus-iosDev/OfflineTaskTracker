import Foundation
import SwiftData

@MainActor
protocol TaskRepository {
    func fetchTasks() throws -> [TaskItem]
    func addTask(_ task: TaskItem) throws
    func deleteTask(_ task: TaskItem) throws
    func save() throws
}

@MainActor
final class SwiftDataTaskRepository: TaskRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchTasks() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func addTask(_ task: TaskItem) throws {
        context.insert(task)
        try context.save()
    }

    func deleteTask(_ task: TaskItem) throws {
        context.delete(task)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
