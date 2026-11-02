import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var viewModel: TaskViewModel?

    var body: some View {
        Group {
            if let viewModel {
                TabView(selection: $selectedTab) {
                    DashboardView(viewModel: viewModel)
                        .tabItem {
                            Label("Overview", systemImage: "square.grid.2x2")
                        }
                        .tag(0)

                    TaskListView(viewModel: viewModel)
                        .tabItem {


                            Label("Tasks", systemImage: "checklist")
                        }
                        .tag(1)
                }
                .tint(.indigo)
            } else {
                ProgressView("Preparing your tasks…")
            }
        }
        .task {
            // Create the ViewModel once and share it between both tabs.
            if viewModel == nil {
                viewModel = TaskViewModel(
                    repository: SwiftDataTaskRepository(context: modelContext)
                )
            }
        }
    }
}
