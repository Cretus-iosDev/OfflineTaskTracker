import XCTest
import SwiftData
@testable import OfflineTaskTracker

final class TaskItemRepositoryTests: XCTestCase {

    // MARK: - TaskItem tests

    func testNewTaskStartsIncomplete() {
        let task = TaskItem(
            title: "Prepare portfolio",
            priority: .high,
            category: .learning
        )

        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
        XCTAssertFalse(task.isOverdue)
    }

    func testCompletingTaskSetsCompletionDate() {
        let task = TaskItem(title: "Write unit tests")

        task.setCompleted(true)

        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedAt)
    }

    func testReopeningTaskClearsCompletionDate() {
        let task = TaskItem(title: "Review pull request")
        task.setCompleted(true)

        task.setCompleted(false)

        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
    }

    func testPastDueIncompleteTaskIsOverdue() {
        let yesterday = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Calendar.current.startOfDay(for: .now)
        )!
        let task = TaskItem(title: "Past deadline", dueDate: yesterday)

        XCTAssertTrue(task.isOverdue)
    }

    func testCompletedPastDueTaskIsNotOverdue() {
        let yesterday = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Calendar.current.startOfDay(for: .now)
        )!
        let task = TaskItem(title: "Finished late", dueDate: yesterday)
        task.setCompleted(true)

        XCTAssertFalse(task.isOverdue)
    }

    func testTaskDueTodayIsNotOverdue() {
        let today = Calendar.current.startOfDay(for: .now)
        let task = TaskItem(title: "Due today", dueDate: today)

        XCTAssertFalse(task.isOverdue)
    }

    // MARK: - SwiftData repository tests

    @MainActor
    func testRepositoryAddsAndFetchesTask() throws {
        let (container, repository) = try makeInMemoryRepository()
        defer { container.mainContext.rollback() }

        let task = TaskItem(
            title: "Offline persistence",
            taskDescription: "Verify SwiftData storage",
            priority: .urgent,
            category: .work
        )

        try repository.addTask(task)

        let fetchedTasks = try repository.fetchTasks()

        XCTAssertEqual(fetchedTasks.count, 1)
        XCTAssertEqual(fetchedTasks.first?.id, task.id)
        XCTAssertEqual(fetchedTasks.first?.title, "Offline persistence")
        XCTAssertEqual(fetchedTasks.first?.taskDescription, "Verify SwiftData storage")
        XCTAssertEqual(fetchedTasks.first?.priority, .urgent)
        XCTAssertEqual(fetchedTasks.first?.category, .work)
    }

    @MainActor
    func testRepositoryDeletesTask() throws {
        let (container, repository) = try makeInMemoryRepository()
        defer { container.mainContext.rollback() }

        let task = TaskItem(title: "Delete me")
        try repository.addTask(task)

        try repository.deleteTask(task)

        XCTAssertTrue(try repository.fetchTasks().isEmpty)
    }

    @MainActor
    func testRepositoryPersistsCompletionChanges() throws {
        let (container, repository) = try makeInMemoryRepository()
        defer { container.mainContext.rollback() }

        let task = TaskItem(title: "Persist completion")
        try repository.addTask(task)

        task.setCompleted(true)
        try repository.save()

        let fetchedTask = try XCTUnwrap(repository.fetchTasks().first)
        XCTAssertTrue(fetchedTask.isCompleted)
        XCTAssertNotNil(fetchedTask.completedAt)
    }

    // MARK: - Test support

    @MainActor
    private func makeInMemoryRepository() throws -> (ModelContainer, SwiftDataTaskRepository) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: TaskItem.self,
            configurations: configuration
        )
        let repository = SwiftDataTaskRepository(context: container.mainContext)
        return (container, repository)
    }
}
