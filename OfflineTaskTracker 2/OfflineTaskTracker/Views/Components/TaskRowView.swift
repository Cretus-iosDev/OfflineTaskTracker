import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark task incomplete" : "Complete task")

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                HStack(spacing: 7) {
                    Label(task.category.title, systemImage: task.category.symbol)
                    Text("•")
                    Text(task.priority.title)
                    if let dueDate = task.dueDate {
                        Text("•")
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor)
                .frame(width: 4, height: 34)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 15))
        .contentShape(RoundedRectangle(cornerRadius: 15))
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: .gray
        case .medium: .blue
        case .high: .orange
        case .urgent: .red
        }
    }
}
