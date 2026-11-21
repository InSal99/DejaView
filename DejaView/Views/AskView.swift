import SwiftUI
import SwiftData

struct AskView: View {
    @Query(sort: \SavedPost.savedAt, order: .reverse) private var posts: [SavedPost]
    @State private var service = AskService()
    @State private var question = ""
    @FocusState private var fieldFocused: Bool

    private let examples: [(symbol: String, text: String)] = [
        ("photo.on.rectangle", "Find the room design post I saved"),
        ("camera.viewfinder", "Show me my screenshots"),
        ("list.bullet.clipboard", "What were the key takeaways from that tutorial?"),
        ("airplane", "Find the travel plan I saved last month")
    ]

    private var canSubmit: Bool {
        !service.isResponding && !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let reason = AskService.unavailableReason {
                        ModelUnavailableBanner(reason: reason)
                    }
                    if !service.hasAsked {
                        emptyState
                    } else {
                        resultsState
                    }
                }
                .padding(16)
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if service.hasAsked {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            question = ""
                            service.reset()
                            fieldFocused = true
                        } label: {
                            Label("New search", systemImage: "plus")
                        }
                        .disabled(service.isResponding)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { searchField }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .accessibilityHidden(true)
                Text("Déjà View")
                    .font(.largeTitle.bold())
                Text("You've seen it before. Now you can find it again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("Try asking…")
                    .font(.headline)
                    .padding(.bottom, 4)
                ForEach(examples, id: \.text) { example in
                    Button {
                        question = example.text
                        submit()
                    } label: {
                        Label(example.text, systemImage: example.symbol)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .surface(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(service.isResponding)
                }
            }
        }
    }

    // MARK: Results

    private var resultsState: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !service.label.isEmpty {
                Label(service.label, systemImage: "magnifyingglass")
                    .font(.caption)
                    .padding(10)
                    .surface(in: Capsule())
            }
            if service.isResponding && service.answerText.isEmpty {
                ProgressView("Searching…")
            }
            if !service.answerText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI Answer", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)
                    Text(service.answerText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .surface(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            if let note = service.relaxedNote { Text(note).font(.footnote).foregroundStyle(.secondary) }
            if let error = service.errorMessage { Text(error).font(.footnote).foregroundStyle(.secondary) }

            if service.results.isEmpty && !service.isResponding {
                ContentUnavailableView("Nothing saved about that yet", systemImage: "magnifyingglass", description: Text("Try another search."))
            } else if !service.results.isEmpty {
                Text("Saved in your library (\(service.results.count))")
                    .font(.headline)
                VStack(spacing: 0) {
                    ForEach(service.results) { result in
                        NavigationLink {
                            PostDetailView(post: result.post)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                PostRowView(post: result.post, showsTags: true)
                                Text(result.reason)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 84)
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Ask or search your saved library…", text: $question)
                .focused($fieldFocused)
                .submitLabel(.search)
                .onSubmit(submit)
            Button("Search", systemImage: "arrow.up.circle.fill", action: submit)
                .labelStyle(.iconOnly)
                .font(.title2)
                .disabled(!canSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground), in: Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func submit() {
        guard canSubmit else { return }
        let prompt = question
        fieldFocused = false
        Task { await service.ask(prompt, posts: posts) }
    }
}
