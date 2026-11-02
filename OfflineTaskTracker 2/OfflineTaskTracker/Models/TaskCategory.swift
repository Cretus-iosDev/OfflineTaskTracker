import Foundation

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case work
    case personal
    case learning

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .work: "briefcase"
        case .personal: "house"
        case .learning: "book"
        }
    }
}
