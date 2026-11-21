import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedPost.savedAt, order: .reverse) private var posts: [SavedPost]
    @State private var category: PostCategory?
    @State private var showingAddLink = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var filteredPosts: [SavedPost] {
        posts.filter { category == nil || $0.category == category }
    }

    var body: some View {
        NavigationStack {
            Group {
                if posts.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing saved yet", systemImage: "rectangle.on.rectangle")
                    } description: {
                        Text("You've seen it before. Now you can find it again. Share a post to Déjà View or paste a link.")
                    } actions: {
                        Button("Paste a link") { showingAddLink = true }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ScrollView(.horizontal) {
                                HStack {
                                    Button("All") { category = nil }
                                        .buttonStyle(.borderedProminent)
                                        .tint(category == nil ? .accentColor : .secondary)
                                    ForEach(PostCategory.allCases.filter { candidate in posts.contains { $0.category == candidate } }, id: \.self) { candidate in
                                        Button { category = candidate } label: {
                                            CategoryChip(category: candidate, selected: category == candidate)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }.scrollIndicators(.hidden)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                                ForEach(filteredPosts) { post in
                                    NavigationLink { PostDetailView(post: post) } label: { PostCardView(post: post) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }.padding(16)
                    }
                }
            }
            .navigationTitle("Déjà View")
            .safeAreaInset(edge: .top) {
                if let reason = AskService.unavailableReason {
                    ModelUnavailableBanner(reason: reason)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .toolbar {
                Button("Save a post", systemImage: "plus") { showingAddLink = true }
                #if DEBUG
                Button("Add sample posts", systemImage: "plus.rectangle.on.rectangle") { addSamplePosts() }
                    .disabled(!posts.isEmpty)
                #endif
            }
            .sheet(isPresented: $showingAddLink) { AddLinkView() }
        }
    }

    #if DEBUG
    private func addSamplePosts() {
        let samples: [(String, String, PostCategory, Platform)] = [
            ("Diera sekarang, kamu gagal jadi designer kalau hasilnya kalah sama AI", "A discussion about designers working with AI.", .design, .instagram),
            ("Resep ayam geprek sambal bawang dengan nasi hangat", "A recipe for spicy smashed chicken and garlic sambal.", .foodRecipes, .tiktok),
            ("A quiet weekend exploring Kyoto's side streets.", "A guide to exploring Kyoto on foot.", .travel, .instagram),
            ("A practical guide to building a small app with Swift.", "Tips for building a Swift app.", .tech, .web),
            ("Five ways to make a daily study habit stick.", "Simple ideas for a consistent study routine.", .tipsLearning, .threads),
            ("A compact desk lamp for small spaces.", "A desk lamp suited to a small workspace.", .shopping, .facebook),
            ("Films to watch on a rainy afternoon.", "A selection of films for a rainy day.", .entertainment, .x),
            ("A few little moments from the weekend.", "A collection of weekend moments.", .other, .screenshot)
        ]
        for (index, sample) in samples.enumerated() {
            let post = SavedPost(platform: sample.3)
            post.caption = sample.0
            post.summary = sample.1
            post.category = sample.2
            post.status = .processed
            post.savedAt = Calendar.current.date(byAdding: .day, value: -index, to: .now) ?? .now
            context.insert(post)
        }
        let review = SavedPost(platform: .tiktok)
        review.caption = "wait for it 😂"
        review.status = .needsReview
        review.statusMessage = "Add a note to help identify this post."
        review.savedAt = Calendar.current.date(byAdding: .day, value: -9, to: .now) ?? .now
        context.insert(review)
        do { try context.save() } catch { context.rollback() }
    }
    #endif
}
