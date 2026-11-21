import SwiftUI
import SwiftData

@main
struct DejaViewApp: App {
    @State private var processor = PostProcessor()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(processor)
                .task { PostAnalyzer.prewarm() }
        }
        .modelContainer(SharedContainer.container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await processor.processPending(in: SharedContainer.container.mainContext) }
            }
        }
    }
}
