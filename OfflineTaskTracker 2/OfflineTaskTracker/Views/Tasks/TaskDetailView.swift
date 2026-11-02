import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let task: TaskItem
    let viewModel: TaskViewModel

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(task.title)
                        .font(.title2.bold())

                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .foregroundStyle(.secondary)
                    }

                    Label(
                        task.isCompleted ? "Completed" : "In progress",
                        systemImage: task.isCompleted
                            ? "checkmark.circle.fill"
                            : "circle.dashed"
                    )
                    .foregroundStyle(task.isCompleted ? .green : .indigo)
                }
                .padding(.vertical, 8)
            }

            Section("Task information") {
                LabeledContent("Priority", value: task.priority.title)
                LabeledContent("Category", value: task.category.title)
                LabeledContent(
                    "Created",
                    value: task.createdAt.formatted(date: .abbreviated, time: .omitted)
                )

                if let dueDate = task.dueDate {
                    LabeledContent(
                        "Due date",
                        value: dueDate.formatted(date: .long, time: .omitted)
                    )
                } else {
                    LabeledContent("Due date", value: "Not set")
                }

                if task.isOverdue {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    viewModel.toggle(task)
                } label: {
                    Label(
                        task.isCompleted ? "Mark as to do" : "Mark as completed",
                        systemImage: task.isCompleted
                            ? "arrow.uturn.backward.circle"
                            : "checkmark.circle"
                    )
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete task", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
                .accessibilityIdentifier("editTaskButton")
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditTaskFormView(task: task, viewModel: viewModel)
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Task", role: .destructive) {
                viewModel.delete(task)
                dismiss()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

private struct EditTaskFormView: View {
    @Environment(\.dismiss) private var dismiss

    let task: TaskItem
    let viewModel: TaskViewModel

    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    @State private var category: TaskCategory
    @State private var hasDueDate: Bool
    @State private var dueDate: Date

    init(task: TaskItem, viewModel: TaskViewModel) {
        self.task = task
        self.viewModel = viewModel

        _title = State(initialValue: task.title)
        _description = State(initialValue: task.taskDescription)
        _priority = State(initialValue: task.priority)
        _category = State(initialValue: task.category)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs to get done?", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("editTaskTitleField")

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
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.update(
                            task,
                            title: title,
                            description: description,
                            priority: priority,
                            category: category,
                            dueDate: hasDueDate ? dueDate : nil
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("saveEditedTaskButton")
                }
            }
        }
    }
}
