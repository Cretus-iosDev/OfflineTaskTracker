import SwiftUI

struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: TaskViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var category: TaskCategory = .work
    @State private var hasDueDate = false
    @State private var dueDate = Date.now

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs to get done?", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("newTaskTitleField")

                    TextField("Add details (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Organization") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                }

                Section("Due date") {
                    Toggle("Set due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker(
                            "Due",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addTask(
                            title: trimmedTitle,
                            description: description,
                            priority: priority,
                            category: category,
                            dueDate: hasDueDate ? dueDate : nil
                        )
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                    .accessibilityIdentifier("saveNewTaskButton")
                }
            }
        }
    }
}
