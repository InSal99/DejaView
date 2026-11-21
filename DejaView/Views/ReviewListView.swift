import SwiftUI
import SwiftData

struct ReviewListView: View {
    @Query(filter: #Predicate<SavedPost> { $0.statusRaw == "needsReview" },
           sort: \SavedPost.savedAt, order: .reverse)
    private var posts: [SavedPost]

    var body: some View {
        NavigationStack {
            Group {
                if posts.isEmpty {
                    ContentUnavailableView("All caught up", systemImage: "checkmark.circle",
                                           description: Text("There are no posts to review."))
                } else {
                    List {
                        Section {
                            ForEach(posts) { post in
                                NavigationLink {
                                    PostDetailView(post: post)
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        PostImage(post: post)
                                            .frame(width: 56, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(post.displayTitle)
                                                .lineLimit(2)
                                            if !post.statusMessage.isEmpty {
                                                Text(post.statusMessage)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Déjà View wasn't sure about these. Fix them when you have a moment.")
                                .textCase(nil)
                        }
                    }
                }
            }
            .navigationTitle("Needs review")
        }
    }
}
