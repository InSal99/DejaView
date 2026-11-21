import SwiftUI
import SwiftData

/// "Refine with AI": the user says what to change, the model rewrites title, description, key points, category and tags.
struct RefineSheet: View {
    let post: SavedPost
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(PostProcessor.self) private var processor

    @State private var instruction = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private let examples = ["Focus on the ingredients", "Make it shorter", "Focus on the steps", "It's about travel, not food"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Focus on the ingredients", text: $instruction, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($focused)
                        .listRowBackground(Color(.secondarySystemBackground))
                } header: {
                    Text("What should change?")
                } footer: {
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }

                Section("Try") {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(examples, id: \.self) { example in
                                Button(example) { instruction = example }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                    .font(.footnote)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color(.secondarySystemBackground))
                }
            }
            .surfaceForm()
            .dismissKeyboardOnTap()
            .navigationTitle("Refine with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isWorking)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isWorking {
                        ProgressView()
                    } else {
                        Button("Refine", action: refine)
                            .disabled(instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }

    private func refine() {
        isWorking = true
        errorMessage = nil
        Task {
            let error = await processor.refine(post, instruction: instruction)
            isWorking = false
            if let error {
                errorMessage = error
            } else {
                try? context.save()
                dismiss()
            }
        }
    }
}
