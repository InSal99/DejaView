import SwiftUI
import SwiftData

struct RootView: View {
    @Query(filter: #Predicate<SavedPost> { $0.statusRaw == "needsReview" })
    private var reviewPosts: [SavedPost]

    var body: some View {
        TabView {
            Tab("Search", systemImage: "magnifyingglass") {
                AskView()
            }

            Tab("Library", systemImage: "square.grid.2x2") {
                LibraryView()
            }

            Tab("Review", systemImage: "tray") {
                ReviewListView()
            }
            .badge(reviewPosts.count)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: SavedPost.self, inMemory: true)
        .environment(PostProcessor())
}
