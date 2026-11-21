import SwiftUI
import SwiftData

struct AskView: View {
    @Query(sort: \SavedPost.savedAt, order: .reverse) private var posts: [SavedPost]
    @State private var service = AskService()
    @State private var question = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let examples = ["Design posts from this week", "Recipes I saved", "Travel tips on TikTok"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let reason = AskService.unavailableReason {
                        ModelUnavailableBanner(reason: reason)
                    }
                    if !service.hasAsked {
                        ContentUnavailableView("Ask Déjà View", systemImage: "sparkle.magnifyingglass", description: Text("Find a post by describing it."))
                        ForEach(examples, id: \.self) { example in
                            Button { question = example; submit() } label: {
                                Label(example, systemImage: "sparkles")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                            .disabled(service.isResponding)
                        }
                    } else {
                        if !service.label.isEmpty {
                            Label(service.label, systemImage: "magnifyingglass")
                                .font(.caption)
                                .padding(10)
                                .background(.quaternary, in: Capsule())
                        }
                        if service.isResponding && service.answerText.isEmpty {
                            ProgressView("Searching…")
                        }
                        if !service.answerText.isEmpty {
                            Text(service.answerText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
                        }
                        if let note = service.relaxedNote { Text(note).font(.footnote).foregroundStyle(.secondary) }
                        if let error = service.errorMessage { Text(error).font(.footnote).foregroundStyle(.secondary) }
                        if service.results.isEmpty && !service.isResponding {
                            ContentUnavailableView("Nothing saved about that yet", systemImage: "magnifyingglass", description: Text("Try another search."))
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                            ForEach(service.results) { result in
                                NavigationLink {
                                    PostDetailView(post: result.post)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        PostCardView(post: result.post)
                                        Text(result.reason).font(.caption).foregroundStyle(.secondary)
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }.padding(16)
            }
            .navigationTitle("Ask")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("What are you looking for?", text: $question)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit(submit)
                    Button("Search", systemImage: "arrow.up.circle.fill", action: submit)
                        .labelStyle(.iconOnly)
                        .disabled(service.isResponding || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(.bar)
            }
        }
    }

    private func submit() {
        guard !service.isResponding, !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let prompt = question
        Task { await service.ask(prompt, posts: posts) }
    }
}
