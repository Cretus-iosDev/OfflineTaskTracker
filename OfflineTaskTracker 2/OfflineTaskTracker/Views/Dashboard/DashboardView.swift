import SwiftUI

struct DashboardView: View {
    @State private var viewModel: TaskViewModel
    @State private var showingCreateTask = false

    init(viewModel: TaskViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    overviewSection
                    todaySection
                    upcomingSection
                    prioritySection
                    weeklyActivitySection
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateTask = true } label: {
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now.formatted(date: .complete, time: .omitted).uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text("Make today count.")
                .font(.largeTitle.bold())
            Text("A little progress adds up.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Your overview", subtitle: "A snapshot of your workload")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "To do", value: viewModel.openCount,
                         symbol: "circle.dashed", tint: .indigo)
                StatCard(title: "Completed", value: viewModel.completedCount,
                         symbol: "checkmark.circle.fill", tint: .green)
                StatCard(title: "Overdue", value: viewModel.overdueCount,
                         symbol: "clock.badge.exclamationmark", tint: .orange)
                StatCard(title: "Total tasks", value: viewModel.tasks.count,
                         symbol: "tray.full", tint: .blue)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Completion progress")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(viewModel.completionPercentage)%")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.indigo)
                }
                ProgressView(value: Double(viewModel.completionPercentage), total: 100)
                    .tint(.indigo)
                Text("\(viewModel.completedCount) of \(viewModel.tasks.count) tasks completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Today's tasks", subtitle: "Tasks scheduled for today")
            if viewModel.todayTasks.isEmpty {
                EmptyDashboardCard(
                    title: "Nothing due today",
                    message: "You're clear for today, or you can add a task.",
                    symbol: "sun.max"
                )
            } else {
                taskRows(viewModel.todayTasks)
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Upcoming deadlines", subtitle: "Due over the next 7 days")
            if viewModel.upcomingDeadlineTasks.isEmpty {
                EmptyDashboardCard(
                    title: "No upcoming deadlines",
                    message: "Tasks due in the next seven days will appear here.",
                    symbol: "calendar"
                )
            } else {
                taskRows(viewModel.upcomingDeadlineTasks)
            }
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Priority overview", subtitle: "Open tasks by priority")
            VStack(spacing: 0) {
                ForEach(TaskPriority.allCases) { priority in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(priorityColor(for: priority))
                            .frame(width: 9, height: 9)
                        Text(priority.title)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(viewModel.priorityCount(for: priority))")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 11)
                    if priority.id != TaskPriority.allCases.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("This week's activity", subtitle: "Tasks created since the start of this week")
            HStack(spacing: 14) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.indigo)
                    .frame(width: 46, height: 46)
                    .background(.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(viewModel.tasksCreatedThisWeek)")
                        .font(.title.bold().monospacedDigit())
                    Text("Tasks created this week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func taskRows(_ tasks: [TaskItem]) -> some View {
        VStack(spacing: 10) {
            ForEach(tasks) { task in
                NavigationLink {
                    TaskDetailView(task: task, viewModel: viewModel)
                } label: {
                    TaskRowView(task: task) {
                        viewModel.toggle(task)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title2.bold())
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority.sortOrder {
        case 0: return .red
        case 1: return .orange
        case 2: return .blue
        default: return .gray
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol).font(.title3).foregroundStyle(tint)
            Text("\(value)").font(.system(size: 30, weight: .bold, design: .rounded))
            Text(title).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct EmptyDashboardCard: View {
    let title: String
    let message: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}
