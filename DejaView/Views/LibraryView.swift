import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedPost.savedAt, order: .reverse) private var posts: [SavedPost]
    @State private var source: SourceFilter = .all
    @State private var showingAddLink = false
    @State private var postToDelete: SavedPost?
    @State private var errorMessage: String?

    enum SourceFilter: String, CaseIterable, Identifiable {
        case all = "All", posts = "Posts", screenshots = "Screenshots", links = "Links"
        var id: Self { self }
        func includes(_ kind: SourceKind) -> Bool {
            switch self {
            case .all: true
            case .posts: kind == .post
            case .screenshots: kind == .screenshot
            case .links: kind == .link
            }
        }
    }

    private var filteredPosts: [SavedPost] {
        posts.filter { source.includes($0.sourceKind) }
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
                    List {
                        Section {
                            Picker("Source", selection: $source) {
                                ForEach(SourceFilter.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        Section {
                            ForEach(filteredPosts) { post in
                                NavigationLink {
                                    PostDetailView(post: post)
                                } label: {
                                    PostRowView(post: post) { postToDelete = post }
                                }
                            }
                            if filteredPosts.isEmpty {
                                Text("Nothing here yet.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let errorMessage {
                            Text(errorMessage).font(.footnote).foregroundStyle(.red)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Library")
            .safeAreaInset(edge: .top) {
                if let reason = AskService.unavailableReason {
                    ModelUnavailableBanner(reason: reason)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .toolbar {
                Button("Save a post", systemImage: "plus") { showingAddLink = true }
            }
            .sheet(isPresented: $showingAddLink) { AddLinkView() }
            .confirmationDialog("Delete this post?", isPresented: Binding(
                get: { postToDelete != nil },
                set: { if !$0 { postToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let post = postToDelete {
                        context.delete(post)
                        do { try context.save(); errorMessage = nil } catch { context.rollback(); errorMessage = "Couldn't delete this post. Please try again." }
                    }
                    postToDelete = nil
                }
            }
        }
    }
}
