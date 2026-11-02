import XCTest
@testable import OfflineTaskTracker

@MainActor
final class TaskViewModelTests: XCTestCase {

    private func makeSUT() -> (TaskViewModel, InMemoryTaskRepository) {
        let repository = InMemoryTaskRepository()
        let viewModel = TaskViewModel(repository: repository)
        return (viewModel, repository)
    }

    private func date(_ daysFromToday: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysFromToday, to: Calendar.current.startOfDay(for: .now))!
    }

    // MARK: - CRUD

    func testAddTaskTrimsTitleAndDescription() {
        let (viewModel, _) = makeSUT()

        viewModel.addTask(
            title: "  Prepare portfolio  ",
            description: "  Build the app  ",
            priority: .high,
            category: .learning,
            dueDate: date(2)
        )

        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "Prepare portfolio")
        XCTAssertEqual(viewModel.tasks.first?.taskDescription, "Build the app")
        XCTAssertEqual(viewModel.tasks.first?.priority, .high)
        XCTAssertEqual(viewModel.tasks.first?.category, .learning)
    }

    func testAddTaskIgnoresBlankTitle() {
        let (viewModel, _) = makeSUT()

        viewModel.addTask(
            title: "   \n ",
            description: "Description",
            priority: .medium,
            category: .work,
            dueDate: nil
        )

        XCTAssertTrue(viewModel.tasks.isEmpty)
    }

    func testUpdateChangesTaskFieldsAndTrimsText() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(
            title: "Old title",
            description: "Old description",
            priority: .low,
            category: .work,
            dueDate: nil
        )
        let task = viewModel.tasks[0]

        viewModel.update(
            task,
            title: "  New title ",
            description: " New description  ",
            priority: .urgent,
            category: .personal,
            dueDate: date(3)
        )

        XCTAssertEqual(task.title, "New title")
        XCTAssertEqual(task.taskDescription, "New description")
        XCTAssertEqual(task.priority, .urgent)
        XCTAssertEqual(task.category, .personal)
        XCTAssertEqual(task.dueDate, date(3))
    }

    func testUpdateIgnoresBlankTitle() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Keep this", description: "", priority: .low,
                          category: .work, dueDate: nil)
        let task = viewModel.tasks[0]

        viewModel.update(task, title: " ", description: "Changed", priority: .urgent,
                         category: .personal, dueDate: nil)

        XCTAssertEqual(task.title, "Keep this")
        XCTAssertEqual(task.taskDescription, "")
    }

    func testToggleCompletesAndReopensTask() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Toggle me", description: "", priority: .medium,
                          category: .work, dueDate: nil)
        let task = viewModel.tasks[0]

        viewModel.toggle(task)
        XCTAssertTrue(task.isCompleted)

        viewModel.toggle(task)
        XCTAssertFalse(task.isCompleted)
    }

    func testDeleteRemovesTask() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Delete me", description: "", priority: .low,
                          category: .work, dueDate: nil)
        let task = viewModel.tasks[0]

        viewModel.delete(task)

        XCTAssertTrue(viewModel.tasks.isEmpty)
    }

    // MARK: - Search and filters

    func testSearchMatchesTitleAndDescriptionCaseInsensitively() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Prepare Report", description: "Quarterly numbers",
                          priority: .medium, category: .work, dueDate: nil)
        viewModel.addTask(title: "Read book", description: "SwiftUI NOTES",
                          priority: .low, category: .personal, dueDate: nil)

        viewModel.searchText = "report"
        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Prepare Report"])

        viewModel.searchText = "swiftui"
        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Read book"])
    }

    func testStatusScopeFiltersOpenAndCompletedTasks() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Open", description: "", priority: .low,
                          category: .work, dueDate: nil)
        viewModel.addTask(title: "Done", description: "", priority: .low,
                          category: .work, dueDate: nil)
        viewModel.toggle(viewModel.tasks.first { $0.title == "Done" }!)

        viewModel.selectedScope = .open
        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Open"])

        viewModel.selectedScope = .completed
        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Done"])
    }

    func testCategoryFilter() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Work item", description: "", priority: .low,
                          category: .work, dueDate: nil)
        viewModel.addTask(title: "Personal item", description: "", priority: .low,
                          category: .personal, dueDate: nil)

        viewModel.selectedCategory = .personal

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Personal item"])
    }

    func testOverdueScopeExcludesCompletedOverdueTasks() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Late open", description: "", priority: .low,
                          category: .work, dueDate: date(-2))
        viewModel.addTask(title: "Late done", description: "", priority: .low,
                          category: .work, dueDate: date(-3))
        viewModel.toggle(viewModel.tasks.first { $0.title == "Late done" }!)

        viewModel.selectedScope = .overdue

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Late open"])
    }

    // MARK: - Date filters

    func testDueTodayFilter() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Today", description: "", priority: .medium,
                          category: .work, dueDate: date(0))
        viewModel.addTask(title: "Tomorrow", description: "", priority: .medium,
                          category: .work, dueDate: date(1))

        viewModel.selectedDateFilter = .dueToday

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Today"])
    }

    func testDueThisWeekFilter() {
        let (viewModel, _) = makeSUT()
        let calendar = Calendar.current
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: .now)!.end
        let lastMomentThisWeek = calendar.date(byAdding: .second, value: -1, to: weekEnd)!

        viewModel.addTask(title: "This week", description: "", priority: .medium,
                          category: .work, dueDate: date(1))
        viewModel.addTask(title: "Next week", description: "", priority: .medium,
                          category: .work, dueDate: weekEnd)
        viewModel.addTask(title: "Overdue", description: "", priority: .medium,
                          category: .work, dueDate: date(-1))

        viewModel.selectedDateFilter = .dueThisWeek

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["This week"])
        XCTAssertNotNil(lastMomentThisWeek)
    }

    func testUpcomingFilterMeansAfterCurrentCalendarWeek() {
        let (viewModel, _) = makeSUT()
        let weekEnd = Calendar.current.dateInterval(of: .weekOfYear, for: .now)!.end

        viewModel.addTask(title: "This week", description: "", priority: .medium,
                          category: .work, dueDate: date(1))
        viewModel.addTask(title: "Upcoming", description: "", priority: .medium,
                          category: .work, dueDate: weekEnd)

        viewModel.selectedDateFilter = .upcoming

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Upcoming"])
    }

    func testOverdueDateFilter() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Late", description: "", priority: .medium,
                          category: .work, dueDate: date(-1))
        viewModel.addTask(title: "Future", description: "", priority: .medium,
                          category: .work, dueDate: date(1))

        viewModel.selectedDateFilter = .overdue

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Late"])
    }

    // MARK: - Sorting

    func testPriorityHighToLowSort() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Low", description: "", priority: .low, category: .work, dueDate: nil)
        viewModel.addTask(title: "Urgent", description: "", priority: .urgent, category: .work, dueDate: nil)
        viewModel.addTask(title: "Medium", description: "", priority: .medium, category: .work, dueDate: nil)
        viewModel.addTask(title: "High", description: "", priority: .high, category: .work, dueDate: nil)

        viewModel.selectedSort = .priorityHighToLow

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Urgent", "High", "Medium", "Low"])
    }

    func testPriorityLowToHighSort() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Low", description: "", priority: .low, category: .work, dueDate: nil)
        viewModel.addTask(title: "Urgent", description: "", priority: .urgent, category: .work, dueDate: nil)
        viewModel.addTask(title: "Medium", description: "", priority: .medium, category: .work, dueDate: nil)
        viewModel.addTask(title: "High", description: "", priority: .high, category: .work, dueDate: nil)

        viewModel.selectedSort = .priorityLowToHigh

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Low", "Medium", "High", "Urgent"])
    }

    func testDueDateSortPlacesDatedTasksBeforeTasksWithoutDueDate() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "No date", description: "", priority: .medium,
                          category: .work, dueDate: nil)
        viewModel.addTask(title: "Later", description: "", priority: .medium,
                          category: .work, dueDate: date(5))
        viewModel.addTask(title: "Sooner", description: "", priority: .medium,
                          category: .work, dueDate: date(2))

        viewModel.selectedSort = .dueDateEarliest

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Sooner", "Later", "No date"])
    }

    func testActiveTasksStayAboveCompletedTasks() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Completed urgent", description: "", priority: .urgent,
                          category: .work, dueDate: nil)
        viewModel.addTask(title: "Open low", description: "", priority: .low,
                          category: .work, dueDate: nil)
        viewModel.toggle(viewModel.tasks.first { $0.title == "Completed urgent" }!)

        viewModel.selectedSort = .priorityHighToLow

        XCTAssertEqual(viewModel.visibleTasks.map(\.title), ["Open low", "Completed urgent"])
    }

    // MARK: - Dashboard calculations

    func testDashboardCountsAndCompletionPercentage() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "One", description: "", priority: .low, category: .work, dueDate: nil)
        viewModel.addTask(title: "Two", description: "", priority: .high, category: .work, dueDate: nil)
        viewModel.addTask(title: "Three", description: "", priority: .urgent, category: .work, dueDate: nil)
        viewModel.toggle(viewModel.tasks.first { $0.title == "One" }!)

        XCTAssertEqual(viewModel.openCount, 2)
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertEqual(viewModel.tasks.count, 3)
        XCTAssertEqual(viewModel.completionPercentage, 33)
    }

    func testEmptyDashboardHasZeroPercentCompletion() {
        let (viewModel, _) = makeSUT()

        XCTAssertEqual(viewModel.completionPercentage, 0)
        XCTAssertEqual(viewModel.openCount, 0)
        XCTAssertEqual(viewModel.completedCount, 0)
    }

    func testPriorityCountsIncludeOnlyOpenTasks() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Urgent open", description: "", priority: .urgent,
                          category: .work, dueDate: nil)
        viewModel.addTask(title: "Urgent done", description: "", priority: .urgent,
                          category: .work, dueDate: nil)
        viewModel.toggle(viewModel.tasks.first { $0.title == "Urgent done" }!)

        XCTAssertEqual(viewModel.priorityCount(for: .urgent), 1)
    }

    func testTodayAndUpcomingDashboardTasksExcludeCompletedTasks() {
        let (viewModel, _) = makeSUT()
        viewModel.addTask(title: "Today", description: "", priority: .medium,
                          category: .work, dueDate: date(0))
        viewModel.addTask(title: "Tomorrow", description: "", priority: .medium,
                          category: .work, dueDate: date(1))
        viewModel.addTask(title: "Completed today", description: "", priority: .medium,
                          category: .work, dueDate: date(0))
        viewModel.toggle(viewModel.tasks.first { $0.title == "Completed today" }!)

        XCTAssertEqual(viewModel.todayTasks.map(\.title), ["Today"])
        XCTAssertEqual(viewModel.upcomingDeadlineTasks.map(\.title), ["Tomorrow"])
    }
}

@MainActor
private final class InMemoryTaskRepository: TaskRepository {
    private(set) var storedTasks: [TaskItem] = []

    func fetchTasks() throws -> [TaskItem] {
        storedTasks
    }

    func addTask(_ task: TaskItem) throws {
        storedTasks.append(task)
    }

    func deleteTask(_ task: TaskItem) throws {
        storedTasks.removeAll { $0.id == task.id }
    }

    func save() throws {
        // Objects are retained by reference for isolated ViewModel tests.
    }
}
