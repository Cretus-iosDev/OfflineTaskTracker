import SwiftUI
import SwiftData

@main
struct OfflineTaskTrackerApp: App {
    private let container: ModelContainer

    init() {
        do {
            let schema = Schema([TaskItem.self])
            let configuration = ModelConfiguration(
                "OfflineTaskTracker",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create the local task database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppLaunchView()
        }
        .modelContainer(container)
    }
}
