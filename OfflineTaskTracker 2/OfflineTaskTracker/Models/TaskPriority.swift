import Foundation

enum TaskPriority: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high
    case urgent

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var sortOrder: Int {
        switch self {
        case .urgent: 0
        case .high: 1
        case .medium: 2
        case .low: 3
        }
    }
}
