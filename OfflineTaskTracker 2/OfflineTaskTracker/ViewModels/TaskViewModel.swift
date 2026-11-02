import Foundation
import SwiftData

@MainActor
@Observable
final class TaskViewModel {
    private let repository: TaskRepository
    private(set) var tasks: [TaskItem] = []
    var searchText = ""
    var selectedScope: TaskScope = .all
    var selectedCategory: TaskCategory?
    var selectedSort: TaskSortOption = .priorityHighToLow
    var selectedDateFilter: TaskDateFilter = .all
    private(set) var errorMessage: String?

    init(repository: TaskRepository) {
        self.repository = repository
        refresh()
    }

    var visibleTasks: [TaskItem] {
        let filteredTasks = tasks.filter { task in
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || task.title.localizedCaseInsensitiveContains(query)
                || task.taskDescription.localizedCaseInsensitiveContains(query)

            let matchesScope: Bool
            switch selectedScope {
            case .all: matchesScope = true
            case .open: matchesScope = !task.isCompleted
            case .completed: matchesScope = task.isCompleted
            case .overdue: matchesScope = task.isOverdue
            }

            let matchesCategory = selectedCategory == nil || task.category == selectedCategory
            let matchesDate = matchesSelectedDateFilter(task)
            return matchesSearch && matchesScope && matchesCategory && matchesDate
        }

        return filteredTasks.sorted { lhs, rhs in
            // Keep active tasks above completed tasks for every sort option.
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }

            switch selectedSort {
            case .dueDateEarliest:
                return compareDueDates(lhs, rhs, ascending: true)
            case .dueDateLatest:
                return compareDueDates(lhs, rhs, ascending: false)
            case .priorityHighToLow:
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder < rhs.priority.sortOrder
                }
                return lhs.createdAt > rhs.createdAt
            case .priorityLowToHigh:
                if lhs.priority.sortOrder != rhs.priority.sortOrder {
                    return lhs.priority.sortOrder > rhs.priority.sortOrder
                }
                return lhs.createdAt > rhs.createdAt
            case .recentlyCreated:
                return lhs.createdAt > rhs.createdAt
            }
        }
    }

    private func matchesSelectedDateFilter(_ task: TaskItem) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        switch selectedDateFilter {
        case .all:
            return true
        case .overdue:
            return task.isOverdue
        case .dueToday:
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today)
        case .dueThisWeek:
            guard let dueDate = task.dueDate,
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
                return false
            }
            let dueDay = calendar.startOfDay(for: dueDate)
            return dueDay >= today && dueDay < weekInterval.end
        case .upcoming:
            guard let dueDate = task.dueDate,
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
                return false
            }
            return calendar.startOfDay(for: dueDate) >= weekInterval.end
        }
    }

    private func compareDueDates(_ lhs: TaskItem, _ rhs: TaskItem, ascending: Bool) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
        case let (leftDate?, rightDate?):
            if leftDate == rightDate {
                return lhs.createdAt > rhs.createdAt
            }
            return ascending ? leftDate < rightDate : leftDate > rightDate
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.createdAt > rhs.createdAt
        }
    }

    var openCount: Int { tasks.filter { !$0.isCompleted }.count }
    var completedCount: Int { tasks.filter(\.isCompleted).count }
    var overdueCount: Int { tasks.filter(\.isOverdue).count }

    var completionPercentage: Int {
        guard !tasks.isEmpty else { return 0 }
        return Int((Double(completedCount) / Double(tasks.count) * 100).rounded())
    }

    var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        return tasks
            .filter { task in
                guard !task.isCompleted, let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: .now)
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var upcomingDeadlineTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let endOfWindow = calendar.date(byAdding: .day, value: 7, to: today) else { return [] }

        return tasks
            .filter { task in
                guard !task.isCompleted, let dueDate = task.dueDate else { return false }
                let dueDay = calendar.startOfDay(for: dueDate)
                return dueDay > today && dueDay < endOfWindow
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(5)
            .map { $0 }
    }

    // Uses createdAt, which is available in the current model. This is creation activity,
    // not a completion-history metric.
    var tasksCreatedThisWeek: Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return 0 }
        return tasks.filter { $0.createdAt >= startOfWeek }.count
    }

    func priorityCount(for priority: TaskPriority) -> Int {
        tasks.filter { !$0.isCompleted && $0.priority == priority }.count
    }

    func refresh() {
        do {
            tasks = try repository.fetchTasks()
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load tasks: \(error.localizedDescription)"
        }
    }

    func addTask(title: String, description: String, priority: TaskPriority,
                 category: TaskCategory, dueDate: Date?) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        do {
            try repository.addTask(TaskItem(
                title: cleanTitle,
                taskDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                category: category,
                dueDate: dueDate
            ))
            refresh()
        } catch {
            errorMessage = "Couldn't save task: \(error.localizedDescription)"
        }
    }

    func toggle(_ task: TaskItem) {
        task.setCompleted(!task.isCompleted)
        persistChanges()
    }

    func update(_ task: TaskItem, title: String, description: String,
                priority: TaskPriority, category: TaskCategory, dueDate: Date?) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        task.title = cleanTitle
        task.taskDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        task.priority = priority
        task.category = category
        task.dueDate = dueDate
        task.updatedAt = .now
        persistChanges()
    }

    func delete(_ task: TaskItem) {
        do {
            try repository.deleteTask(task)
            refresh()
        } catch {
            errorMessage = "Couldn't delete task: \(error.localizedDescription)"
        }
    }

    private func persistChanges() {
        do {
            try repository.save()
            refresh()
        } catch {
            errorMessage = "Couldn't save changes: \(error.localizedDescription)"
        }
    }
}

enum TaskScope: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "To do"
    case completed = "Completed"
    case overdue = "Overdue"

    var id: String { rawValue }
}

enum TaskSortOption: String, CaseIterable, Identifiable {
    case dueDateEarliest = "Due date: Earliest first"
    case dueDateLatest = "Due date: Latest first"
    case priorityHighToLow = "Priority: High to Low"
    case priorityLowToHigh = "Priority: Low to High"
    case recentlyCreated = "Recently created"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .dueDateEarliest: "calendar"
        case .dueDateLatest: "calendar.badge.clock"
        case .priorityHighToLow: "arrow.down"
        case .priorityLowToHigh: "arrow.up"
        case .recentlyCreated: "clock"
        }
    }
}

enum TaskDateFilter: String, CaseIterable, Identifiable {
    case all = "All dates"
    case dueToday = "Due Today"
    case dueThisWeek = "Due This Week"
    case upcoming = "Upcoming"
    case overdue = "Overdue"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: "calendar"
        case .dueToday: "sun.max"
        case .dueThisWeek: "calendar.badge.clock"
        case .upcoming: "calendar.badge.plus"
        case .overdue: "exclamationmark.circle"
        }
    }
}
