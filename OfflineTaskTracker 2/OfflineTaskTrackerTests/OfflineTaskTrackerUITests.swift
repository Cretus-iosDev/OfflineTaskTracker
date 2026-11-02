import XCTest

final class OfflineTaskTrackerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Helpers

    private func openTasksTab() {
        let tasksTab = app.tabBars.buttons["Tasks"]
        XCTAssertTrue(tasksTab.waitForExistence(timeout: 5), "Tasks tab should be visible.")
        tasksTab.tap()
    }

    private func createTask(titled title: String) {
        openTasksTab()

        let addTaskButton = app.buttons["Add task"]
        XCTAssertTrue(addTaskButton.waitForExistence(timeout: 5), "Add task button should be visible.")
        addTaskButton.tap()

        let titleField = app.textFields["newTaskTitleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "New task title field should be visible.")
        titleField.tap()
        titleField.typeText(title)

        let saveButton = app.buttons["saveNewTaskButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should be visible.")
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled after entering a title.")
        saveButton.tap()

        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5),
                      "Created task should appear in the task list.")
    }

    private func openTask(titled title: String) {
        let taskTitle = app.staticTexts[title]
        XCTAssertTrue(taskTitle.waitForExistence(timeout: 5), "Task should exist before opening.")
        taskTitle.tap()

        XCTAssertTrue(app.navigationBars["Task Details"].waitForExistence(timeout: 5),
                      "Task details screen should open.")
    }

    // MARK: - Tests

    func testAppLaunchesAndShowsMainTabs() {
        XCTAssertTrue(app.tabBars.buttons["Overview"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Tasks"].exists)
    }

    func testCreateTaskAndVerifyItInList() {
        let title = "UITest Create \(UUID().uuidString.prefix(6))"
        createTask(titled: title)
    }

    func testCompleteAndReopenTask() {
        let title = "UITest Complete \(UUID().uuidString.prefix(6))"
        createTask(titled: title)
        openTask(titled: title)

        let completeButton = app.buttons["Mark as completed"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 5))
        completeButton.tap()

        let reopenButton = app.buttons["Mark as to do"]
        XCTAssertTrue(reopenButton.waitForExistence(timeout: 5),
                      "Completed task should offer the option to mark it as to do.")
        reopenButton.tap()

        XCTAssertTrue(app.buttons["Mark as completed"].waitForExistence(timeout: 5),
                      "Reopened task should offer the option to mark it completed again.")
    }

    func testEditTaskTitle() {
        let originalTitle = "UITest Edit \(UUID().uuidString.prefix(6))"
        let updatedTitle = "\(originalTitle) Updated"

        createTask(titled: originalTitle)
        openTask(titled: originalTitle)

        let editButton = app.buttons["editTaskButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let titleField = app.textFields["editTaskTitleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5),
                      "Edit task title field should be visible.")
        titleField.tap()
        titleField.press(forDuration: 1.1)

        // Select all text where the system edit menu exposes that action.
        if app.menuItems["Select All"].waitForExistence(timeout: 2) {
            app.menuItems["Select All"].tap()
            titleField.typeText(updatedTitle)
        } else {
            // Fallback: clear the existing value using the keyboard.
            let existingValue = (titleField.value as? String) ?? ""
            if !existingValue.isEmpty {
                titleField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue,
                                           count: existingValue.count))
            }
            titleField.typeText(updatedTitle)
        }

        let saveButton = app.buttons["saveEditedTaskButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        XCTAssertTrue(app.staticTexts[updatedTitle].waitForExistence(timeout: 5),
                      "Updated title should be visible after saving.")
    }

    func testDeleteTaskFromDetails() {
        let title = "UITest Delete \(UUID().uuidString.prefix(6))"
        createTask(titled: title)
        openTask(titled: title)

        let deleteButton = app.buttons["Delete task"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let confirmDeleteButton = app.buttons["Delete Task"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5),
                      "Delete confirmation action should appear.")
        confirmDeleteButton.tap()

        XCTAssertTrue(app.staticTexts["No tasks yet"].waitForExistence(timeout: 5)
                      || !app.staticTexts[title].exists,
                      "Deleted task should no longer appear in the list.")
    }
}
