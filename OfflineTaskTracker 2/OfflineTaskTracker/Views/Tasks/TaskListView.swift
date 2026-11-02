import SwiftUI

struct TaskListView: View {
    @State private var viewModel: TaskViewModel
    @State private var showingCreateTask = false

    init(viewModel: TaskViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Task status", selection: $viewModel.selectedScope) {
                    ForEach(TaskScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                dateFilterChips

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        categoryChip(nil, title: "All categories")

                        ForEach(TaskCategory.allCases) { category in
                            categoryChip(category, title: category.title)
                        }
                    }
                    .padding(.horizontal)
                }

                if viewModel.visibleTasks.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.visibleTasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task, viewModel: viewModel)
                            } label: {
                                TaskRowView(task: task) {
                                    viewModel.toggle(task)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            let tasks = viewModel.visibleTasks
                            offsets.map { tasks[$0] }.forEach(viewModel.delete)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("My Tasks")
            .searchable(text: $viewModel.searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    sortMenu

                    Button {
                        showingCreateTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add task")
                }
            }
            .sheet(isPresented: $showingCreateTask) {
                TaskFormView(viewModel: viewModel)
            }
        }
    }

    private var dateFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskDateFilter.allCases) { filter in
                    dateFilterChip(filter)
                }
            }
            .padding(.horizontal)
        }
    }

    private func dateFilterChip(_ filter: TaskDateFilter) -> some View {
        let isSelected = viewModel.selectedDateFilter == filter

        return Button {
            viewModel.selectedDateFilter = filter
        } label: {
            Label(filter.rawValue, systemImage: filter.symbol)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    isSelected ? Color.indigo : Color(uiColor: .secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort tasks", selection: $viewModel.selectedSort) {
                ForEach(TaskSortOption.allCases) { option in
                    Label(option.rawValue, systemImage: option.symbol)
                        .tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort tasks")
        .accessibilityIdentifier("sortTasksMenu")
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else if viewModel.tasks.isEmpty {
            ContentUnavailableView {
                Label("No tasks yet", systemImage: "checklist")
            } description: {
                Text("Create your first task and keep your work organized.")
            } actions: {
                Button {
                    showingCreateTask = true
                } label: {
                    Label("Create task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
        } else {
            ContentUnavailableView {
                Label(emptyFilterTitle, systemImage: emptyFilterSymbol)
            } description: {
                Text(emptyFilterDescription)
            }
        }
    }

    private var emptyFilterTitle: String {
        if viewModel.selectedCategory != nil || viewModel.selectedDateFilter != .all {
            return "No matching tasks"
        }

        switch viewModel.selectedScope {
        case .all:
            return "No matching tasks"
        case .open:
            return "No tasks to do"
        case .completed:
            return "No completed tasks"
        case .overdue:
            return "You're all caught up"
        }
    }

    private var emptyFilterDescription: String {
        if viewModel.selectedDateFilter != .all {
            return "There are no tasks for the \(viewModel.selectedDateFilter.rawValue.lowercased()) filter. Try another date filter."
        }

        if let category = viewModel.selectedCategory {
            return "There are no tasks in the \(category.title) category for this selection. Try another category or status."
        }

        switch viewModel.selectedScope {
        case .all:
            return "Try changing your filters to see more tasks."
        case .open:
            return "Tasks that still need attention will appear here."
        case .completed:
            return "Tasks you mark as completed will appear here."
        case .overdue:
            return "You don't have any overdue tasks. Nice work!"
        }
    }

    private var emptyFilterSymbol: String {
        if viewModel.selectedDateFilter != .all {
            return viewModel.selectedDateFilter.symbol
        }

        switch viewModel.selectedScope {
        case .all:
            return "line.3.horizontal.decrease.circle"
        case .open:
            return "circle.dashed"
        case .completed:
            return "checkmark.circle"
        case .overdue:
            return "checkmark.circle.fill"
        }
    }

    private func categoryChip(_ category: TaskCategory?, title: String) -> some View {
        let selected = viewModel.selectedCategory == category

        return Button {
            viewModel.selectedCategory = category
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(
                    selected ? Color.indigo : Color(uiColor: .secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
